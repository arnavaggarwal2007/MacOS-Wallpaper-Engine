import AppKit
import WebKit
import os.log

final class WebRenderer: Renderer {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "WebRenderer")
    private weak var containerView: NSView?
    private var webView: WKWebView?
    private var activeURL: URL?

    func start(in containerView: NSView) async -> Result<Void, WallpaperError> {
        self.containerView = containerView

        // Configure WKWebView for macOS: avoid using iOS-only APIs like `allowsInlineMediaPlayback`.
        let configuration = WKWebViewConfiguration()
        // Allow autoplay by not requiring a user action for media playback
        if #available(macOS 10.13, *) {
            configuration.mediaTypesRequiringUserActionForPlayback = []
        }

        let preferences = WKPreferences()
        if #available(macOS 11.0, *) {
            var pagePrefs = WKWebpagePreferences()
            pagePrefs.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences = pagePrefs
        } else {
            preferences.javaScriptEnabled = true
            configuration.preferences = preferences
        }

        let webView = WKWebView(frame: containerView.bounds, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = nil
        webView.allowsBackForwardNavigationGestures = false

        containerView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.frame = containerView.bounds

        self.webView = webView
        logger.info("WebRenderer initialized and attached to container view")
        return .success(())
    }

    func stop() async {
        webView?.stopLoading()
        webView?.removeFromSuperview()
        logger.debug("WebRenderer stopped")
    }

    func pause() async {
        await runJavaScript("document.querySelectorAll('video,audio').forEach(e => e.pause());")
    }

    func resume() async {
        await runJavaScript("document.querySelectorAll('video,audio').forEach(e => { try{ e.play(); } catch(e){} });")
    }

    func setMuted(_ isMuted: Bool) async {
        let muteValue = isMuted ? "true" : "false"
        let js = "document.querySelectorAll('video,audio').forEach(e => e.muted = " + muteValue + ");"
        await runJavaScript(js)
    }

    func setScalingMode(_ mode: VideoScalingMode) async {
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
        containerView = nil
        activeURL = nil
        logger.debug("WebRenderer disposed")
    }

    // MARK: - Load URL
    func load(url: URL) async -> Result<Void, WallpaperError> {
        activeURL = url

        guard let webView = webView else {
            return .failure(.rendererInitializationFailed(reason: "WebView not initialized"))
        }

        let request = URLRequest(url: url)
        await MainActor.run {
            webView.load(request)
        }

        return .success(())
    }

    // MARK: - Reconciliation Query Methods
    func isMuted() async -> Bool {
        let result = await evaluateJavaScript("(function(){const v=document.querySelector('video'); return v? v.muted : true})()")
        if let boolVal = result as? Bool { return boolVal }
        return true
    }

    func scalingMode() async -> VideoScalingMode {
        return .resizeAspectFill
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
