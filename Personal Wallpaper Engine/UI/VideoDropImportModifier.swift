import SwiftUI
import UniformTypeIdentifiers

extension View {
    func videoDropImport(isTargeted: Binding<Bool>? = nil, onVideoURL: @escaping (URL) -> Void) -> some View {
        onDrop(
            of: VideoDropImport.supportedContentTypes,
            isTargeted: isTargeted
        ) { providers in
            guard !providers.isEmpty else { return false }
            Task { @MainActor in
                if let url = await VideoDropImport.firstVideoURL(from: providers) {
                    onVideoURL(url)
                }
            }
            return true
        }
    }
}
