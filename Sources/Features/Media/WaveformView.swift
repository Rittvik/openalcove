import SwiftUI
import Combine

public struct WaveformView: View {
    public let isPlaying: Bool
    public var barCount: Int = 4
    public var activeColor: Color = Color.white
    public var idleColor: Color = Color.white.opacity(0.4)
    public var maxHeight: CGFloat = 14
    
    @State private var barHeights: [CGFloat] = [0.3, 0.7, 0.5, 0.9]
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    
    public init(
        isPlaying: Bool,
        barCount: Int = 4,
        activeColor: Color = Color.white,
        idleColor: Color = Color.white.opacity(0.4),
        maxHeight: CGFloat = 14
    ) {
        self.isPlaying = isPlaying
        self.barCount = barCount
        self.activeColor = activeColor
        self.idleColor = idleColor
        self.maxHeight = maxHeight
        self._barHeights = State(initialValue: (0..<barCount).map { _ in CGFloat.random(in: 0.3...0.9) })
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(isPlaying ? activeColor : idleColor)
                    .frame(
                        width: 2.5,
                        height: isPlaying ? max(3, barHeights[index % barHeights.count] * maxHeight) : 3
                    )
                    .animation(.easeInOut(duration: 0.18), value: barHeights[index % barHeights.count])
            }
        }
        .frame(height: maxHeight)
        .onReceive(timer) { _ in
            if isPlaying {
                for i in 0..<barHeights.count {
                    barHeights[i] = CGFloat.random(in: 0.2...1.0)
                }
            }
        }
    }
}
