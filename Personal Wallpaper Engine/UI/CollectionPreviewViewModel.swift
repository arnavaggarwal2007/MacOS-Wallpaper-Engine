import Foundation

struct CollectionPreviewViewModel: Identifiable {
    let id: String
    let name: String
    let type: String
    let sourceCount: Int
    let lastUpdated: Date?

    init(collection: WallpaperCollection) {
        id = collection.id
        name = collection.name
        type = collection.collectionType.rawValue
        sourceCount = collection.sources.count
        lastUpdated = collection.updatedAt
    }
}
