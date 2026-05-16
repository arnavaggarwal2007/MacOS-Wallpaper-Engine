import SwiftUI
import AppKit

struct DisplayCard: Identifiable {
    let displayID: CGDirectDisplayID
    let title: String
    let subtitle: String
    let badge: String
    let resolution: String
    let scaling: String
    let previewImage: NSImage?
    let isActive: Bool

    var id: CGDirectDisplayID { displayID }
}
