import SwiftUI

public struct MarqueeText: View {
    public let text: String
    public var font: Font = .system(size: 13, weight: .semibold)
    public var color: Color = .white
    
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var isAnimating: Bool = false
    
    public init(text: String, font: Font = .system(size: 13, weight: .semibold), color: Color = .white) {
        self.text = text
        self.font = font
        self.color = color
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let cWidth = proxy.size.width
            ZStack(alignment: .leading) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { textProxy in
                            Color.clear.preference(
                                key: TextWidthPreferenceKey.self,
                                value: textProxy.size.width
                            )
                        }
                    )
                    .offset(x: offset)
            }
            .frame(width: cWidth, alignment: .leading)
            .clipped()
            .onPreferenceChange(TextWidthPreferenceKey.self) { width in
                self.textWidth = width
                self.containerWidth = cWidth
                setupAnimation()
            }
        }
        .frame(height: 18)
    }
    
    private func setupAnimation() {
        guard textWidth > containerWidth, containerWidth > 0 else {
            offset = 0
            isAnimating = false
            return
        }
        
        let scrollDistance = textWidth - containerWidth + 16
        withAnimation(.linear(duration: Double(scrollDistance) / 25.0).repeatForever(autoreverses: true).delay(1.5)) {
            offset = -scrollDistance
        }
    }
}

private struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
