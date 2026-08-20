import Foundation

/// Validates URLs accepted for web wallpaper mode (https and local files only).
enum WebWallpaperURLValidator {
    static let allowedSchemes: Set<String> = ["https", "file"]

    static func isAllowed(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else {
            return url.isFileURL
        }
        return allowedSchemes.contains(scheme)
    }

    /// Parses user input into an allowed wallpaper URL, or nil if invalid.
    static func validatedURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("/") {
            let fileURL = URL(fileURLWithPath: trimmed)
            return isAllowed(fileURL) ? fileURL : nil
        }

        guard let url = URL(string: trimmed) else { return nil }

        if url.scheme == nil, url.path.hasPrefix("/") {
            let fileURL = URL(fileURLWithPath: url.path)
            return isAllowed(fileURL) ? fileURL : nil
        }

        return isAllowed(url) ? url : nil
    }

    static var validationHint: String {
        "Enter an https:// URL or choose a local HTML file. http:// URLs are not supported."
    }
}
