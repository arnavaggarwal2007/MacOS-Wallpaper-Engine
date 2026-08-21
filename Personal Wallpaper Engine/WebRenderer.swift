import AppKit
import WebKit
import os.log

/// Navigation delegate for `WebRenderer`. All state is confined to the main thread: WebKit delivers
/// delegate callbacks there, and the renderer drives loads from the main actor.
final class WebRendererNavigationDelegate: NSObject, WKNavigationDelegate {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "WebRenderer")
    private var loadContinuation: CheckedContinuation<Result<Void, WallpaperError>, Never>?
    private var initialLoadURL: URL?

    func beginLoad(for url: URL) async -> Result<Void, WallpaperError> {
        // A load already in flight will never receive its callbacks now that we are superseding it.
        finishLoad(with: .failure(.internalError(description: "Web page load superseded by a newer load")))
        initialLoadURL = url
        return await withCheckedContinuation { continuation in
            loadContinuation = continuation
        }
    }

    /// Resumes any in-flight load so teardown cannot leave `beginLoad` awaiting forever.
    func cancelPendingLoad() {
        finishLoad(with: .failure(.internalError(description: "Web wallpaper load cancelled")))
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let requestURL = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if navigationAction.navigationType == .other,
           let initialLoadURL,
           requestURL.absoluteString == initialLoadURL.absoluteString {
            decisionHandler(.allow)
            return
        }

        if WebWallpaperURLValidator.isAllowed(requestURL) {
            decisionHandler(.allow)
            return
        }

        logger.warning("Blocked navigation to disallowed URL: \(requestURL.absoluteString, privacy: .public)")
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishLoad(with: .success(()))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finishLoad(with: .failure(.internalError(description: "Web page failed to load: \(error.localizedDescription)")))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finishLoad(with: .failure(.internalError(description: "Web page failed to load: \(error.localizedDescription)")))
    }

    private func finishLoad(with result: Result<Void, WallpaperError>) {
        guard let continuation = loadContinuation else { return }
        loadContinuation = nil
        initialLoadURL = nil
        continuation.resume(returning: result)
    }
}

final class WebRenderer: Renderer {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "WebRenderer")
    private weak var containerView: NSView?
    private var webView: WKWebView?
    private var navigationDelegate: WebRendererNavigationDelegate?
    private var activeURL: URL?
    private var currentScalingMode: VideoScalingMode = .resizeAspectFill
    private var performanceProfile: PerformanceProfile = .balanced
    private var pausedForVisibilityPolicy = false

    func start(in containerView: NSView) async -> Result<Void, WallpaperError> {
        self.containerView = containerView

        containerView.layoutSubtreeIfNeeded()
        let bounds = containerView.bounds
        guard !bounds.isEmpty else {
            logger.error("Container view has zero bounds: \(String(describing: bounds))")
            return .failure(.windowCreationFailed(reason: "Container view has zero bounds after layout"))
        }

        let configuration = WKWebViewConfiguration()
        if #available(macOS 10.13, *) {
            configuration.mediaTypesRequiringUserActionForPlayback = []
        }

        let preferences = WKPreferences()
        if #available(macOS 11.0, *) {
            let pagePrefs = WKWebpagePreferences()
            pagePrefs.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences = pagePrefs
        } else {
            preferences.javaScriptEnabled = true
            configuration.preferences = preferences
        }

        let delegate = WebRendererNavigationDelegate()
        let webView = WKWebView(frame: bounds, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = delegate
        webView.allowsBackForwardNavigationGestures = false

        containerView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.frame = bounds

        self.navigationDelegate = delegate
        self.webView = webView
        logger.info("WebRenderer initialized and attached to container view")
        return .success(())
    }

    func stop() async {
        navigationDelegate?.cancelPendingLoad()
        webView?.stopLoading()
        webView?.removeFromSuperview()
        logger.debug("WebRenderer stopped")
    }

    func pause() async {
        pausedForVisibilityPolicy = true
        await runJavaScript("document.querySelectorAll('video,audio').forEach(e => e.pause());")
        if performanceProfile == .batterySaver {
            await MainActor.run { webView?.stopLoading() }
        }
        logger.debug("WebRenderer paused visibilityPolicy=true profile=\(self.performanceProfile.rawValue, privacy: .public)")
    }

    func resume() async {
        pausedForVisibilityPolicy = false
        await runJavaScript("document.querySelectorAll('video,audio').forEach(e => { try{ e.play(); } catch(e){} });")
        if performanceProfile == .batterySaver, let url = activeURL {
            await reloadIfNeeded(url: url)
        }
        logger.debug("WebRenderer resumed visibilityPolicy=false profile=\(self.performanceProfile.rawValue, privacy: .public)")
    }

    func applyPerformanceProfile(_ profile: PerformanceProfile) async {
        performanceProfile = profile
        logger.debug("WebRenderer performance profile=\(profile.rawValue, privacy: .public)")
    }

    private func reloadIfNeeded(url: URL) async {
        guard let webView else { return }
        if webView.url == nil {
            let request = URLRequest(url: url)
            _ = await MainActor.run { webView.load(request) }
        }
    }

    func setMuted(_ isMuted: Bool) async {
        let muteValue = isMuted ? "true" : "false"
        let js = "document.querySelectorAll('video,audio').forEach(e => e.muted = " + muteValue + ");"
        await runJavaScript(js)
    }

    func setScalingMode(_ mode: VideoScalingMode) async {
        currentScalingMode = mode
        switch mode {
        case .resizeAspectFill:
            await runJavaScript("document.documentElement.style.objectFit='cover';")
        case .resizeAspect:
            await runJavaScript("document.documentElement.style.objectFit='contain';")
        case .resizeAspectHeight:
            await runJavaScript("document.documentElement.style.objectFit='fill';")
        }
    }

    func resize(to newSize: CGSize) async {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.frame = CGRect(origin: .zero, size: newSize)
        }
    }

    func dispose() async {
        await stop()
        webView = nil
        navigationDelegate = nil
        containerView = nil
        activeURL = nil
        currentScalingMode = .resizeAspectFill
        logger.debug("WebRenderer disposed")
    }

    // MARK: - Load URL
    func load(url: URL) async -> Result<Void, WallpaperError> {
        guard WebWallpaperURLValidator.isAllowed(url) else {
            return .failure(.internalError(description: WebWallpaperURLValidator.validationHint))
        }

        activeURL = url

        guard let webView, let navigationDelegate else {
            return .failure(.rendererInitializationFailed(reason: "WebView not initialized"))
        }

        let request = URLRequest(url: url)
        _ = await MainActor.run {
            webView.load(request)
        }

        return await navigationDelegate.beginLoad(for: url)
    }

    // MARK: - Reconciliation Query Methods
    func isMuted() async -> Bool {
        let result = await evaluateJavaScript("(function(){const v=document.querySelector('video'); return v? v.muted : true})()")
        if let boolVal = result as? Bool { return boolVal }
        return true
    }

    func scalingMode() async -> VideoScalingMode {
        currentScalingMode
    }

    func isValid() -> Bool {
        guard let webView = webView else { return false }
        return webView.superview != nil
    }

    // MARK: - Helpers
    private func runJavaScript(_ script: String) async {
        _ = await evaluateJavaScript(script)
    }

    private func evaluateJavaScript(_ script: String) async -> Any? {
        await withCheckedContinuation { cont in
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(script) { result, _ in
                    cont.resume(returning: result)
                }
            }
        }
    }
}
