import Foundation

/// Outbound URLs surfaced in the UI, kept in one place so the App Store and
/// Direct flavors cannot drift from the hosted policy and support pages.
///
/// `releaseNotes` is excluded from App Store builds: App Review guideline 3.1.1
/// forbids pointing users at an external update channel.
enum AppLinks {
    static let privacyPolicy = URL(string: "https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/privacy/")!
    static let support = URL(string: "https://github.com/arnavaggarwal2007/MacOS-Wallpaper-Engine/issues")!

    #if !APP_STORE_BUILD
    static let releaseNotes = URL(string: "https://github.com/arnavaggarwal2007/MacOS-Wallpaper-Engine/releases")!
    #endif
}
