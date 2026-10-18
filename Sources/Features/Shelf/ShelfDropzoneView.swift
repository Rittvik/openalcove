import SwiftUI
import AppKit

public struct ShelvedItem: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL
    public var name: String { url.lastPathComponent }
    public var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

public final class ShelfManager: ObservableObject {
    public static let shared = ShelfManager()
    
    @Published public var items: [ShelvedItem] = []
    
    private init() {}
    
    public func add(urls: [URL]) {
        for url in urls {
            if !items.contains(where: { $0.url == url }) {
                items.append(ShelvedItem(url: url))
            }
        }
    }
    
    public func remove(item: ShelvedItem) {
        items.removeAll { $0.id == item.id }
    }
    
    public func clear() {
        items.removeAll()
    }
}

public struct ShelfDropzoneView: View {
    @ObservedObject var shelf = ShelfManager.shared
    @State private var isTargeted: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Alcove Drop Shelf", systemImage: "tray.and.arrow.down.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                if !shelf.items.isEmpty {
                    Button(action: { shelf.clear() }) {
                        Text("Clear All")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            
            if shelf.items.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 20))
                        .foregroundColor(isTargeted ? .accentColor : .white.opacity(0.4))
                    Text("Drag files here to hold between spaces")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isTargeted ? Color.white.opacity(0.7) : Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shelf.items) { item in
                            VStack(spacing: 4) {
                                Image(nsImage: item.icon)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                Text(item.name)
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(width: 50)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .onDrag {
                                NSItemProvider(contentsOf: item.url) ?? NSItemProvider()
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(minHeight: 60)
            }
        }
        .padding(8)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            var urls: [URL] = []
            let group = DispatchGroup()
            for provider in providers {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        urls.append(url)
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                shelf.add(urls: urls)
                SoundManager.shared.play(.haptic)
            }
            return true
        }
    }
}
