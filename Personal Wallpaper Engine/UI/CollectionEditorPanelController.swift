import SwiftUI
import AppKit
import UniformTypeIdentifiers
import os.log

/// NSPanel-based wrapper for presenting the collection editor as a modal on macOS.
class CollectionEditorPanelController: NSObject {
    
    private var panel: NSPanel?
    
    /// Callback when user saves a collection with edited values (and associated bookmarks)
    var onSaveCollection: ((WallpaperCollection, [String: Data]) -> Void)?
    
    /// Callback when user cancels the edit
    var onCancel: (() -> Void)?
    
    func present(
        initialName: String = "",
        initialDescription: String = "",
        initialType: WallpaperCollection.CollectionType = .simple,
        initialSources: [CollectionSource] = [],
        originalCollectionName: String? = nil,
        existingCollectionNames: Set<String> = []
    ) {
        let rect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 650, height: 580)
        
        panel = NSPanel(
            contentRect: rect,
            styleMask: [.titled, .resizable, .closable],
            backing: .buffered,
            defer: false
        )
        
        panel?.title = "Edit Wallpaper Collection"
        panel?.level = .modalPanel
        
        let contentView = CollectionEditorView(
            initialName: initialName,
            initialDescription: initialDescription,
            initialType: initialType,
            initialSources: initialSources,
            originalCollectionName: originalCollectionName,
            existingCollectionNames: existingCollectionNames,
            onCancel: { [weak self] in
                self?.onCancel?()
                self?.panel?.close()
            },
            onSave: { [weak self] collection, bookmarks in
                self?.onSaveCollection?(collection, bookmarks)
                self?.panel?.close()
            }
        )
        
        let container = NSView(frame: rect)
        container.autoresizingMask = [.width, .height]
        
        let nsView = NSHostingView(rootView: contentView)
        nsView.frame = container.bounds
        nsView.autoresizingMask = [.width, .height]
        container.addSubview(nsView)
        
        panel?.contentView = container
        panel?.makeKeyAndOrderFront(nil)
    }
    
    func result() -> WallpaperCollection? {
        // For Chunk 6 MVP: placeholder - enhance in later chunks
        return nil
    }
    
    func cancel() {
        panel?.close()
    }
}

// CollectionEditorView extracted to UI/CollectionEditorView.swift
