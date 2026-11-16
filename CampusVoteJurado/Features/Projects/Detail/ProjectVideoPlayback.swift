import AVFoundation
import SwiftUI
import UIKit

/// Reproduce el video del proyecto y conserva la posición al agrandarlo.
final class ProjectVideoPlayback: ObservableObject {
    let url: URL
    @Published var player: AVPlayer?
    @Published var position = 0.0
    @Published var duration = 0.0
    @Published var playing = false
    @Published var ratio: CGFloat = 16 / 9
    private var observer: Any?

    init(url: URL) {
        self.url = url
    }

    func start() {
        if player == nil {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try? AVAudioSession.sharedInstance().setActive(true)
            let next = AVPlayer(url: url)
            player = next
            observer = next.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.25, preferredTimescale: 4),
                queue: .main
            ) { [weak self] time in
                self?.refresh(time)
            }
        }
        player?.play()
        playing = true
    }

    func toggle() {
        guard player != nil else {
            start()
            return
        }
        if playing {
            player?.pause()
            playing = false
            return
        }
        if duration > 0, position >= duration - 0.2 {
            player?.seek(to: .zero)
            position = 0
        }
        player?.play()
        playing = true
    }

    func seek(to seconds: Double) {
        let target = max(0, seconds)
        player?.seek(to: CMTime(seconds: target, preferredTimescale: 600))
        position = target
    }

    private func refresh(_ time: CMTime) {
        let seconds = time.seconds
        position = seconds.isFinite ? seconds : 0
        let raw = player?.currentItem?.duration.seconds ?? 0
        if raw.isFinite, raw > 0 { duration = raw }
        playing = (player?.rate ?? 0) > 0
        if let size = player?.currentItem?.presentationSize, size.height > 0 {
            ratio = size.width / size.height
        }
    }

    deinit {
        if let observer, let player {
            player.removeTimeObserver(observer)
        }
        player?.pause()
    }
}

/// Capa del video, sin los controles del sistema.
struct ProjectVideoSurface: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> ProjectVideoLayerView {
        let view = ProjectVideoLayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ view: ProjectVideoLayerView, context: Context) {
        view.playerLayer.player = player
    }
}

final class ProjectVideoLayerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

/// Play, barra de tiempo y el botón de agrandar.
struct ProjectVideoChrome: View {
    @ObservedObject var playback: ProjectVideoPlayback
    let expanded: Bool
    let onResize: () -> Void

    var body: some View {
        ZStack {
            if playback.playing {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: playback.toggle)
                    .accessibilityLabel("Pausar video")
            } else {
                Button(action: playback.toggle) {
                    Circle()
                        .fill(.white.opacity(0.94))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.brand)
                                .offset(x: 2)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reproducir video")
            }

            VStack {
                Spacer()
                timeBar
            }
        }
    }

    private var timeBar: some View {
        let end = playback.duration > 0 ? playback.duration : 1
        let value = min(max(playback.position, 0), end)
        return HStack(spacing: 8) {
            Text(Self.clock(value))
            Slider(
                value: Binding(
                    get: { value },
                    set: { playback.seek(to: $0) }
                ),
                in: 0...end
            )
            .tint(.white)
            Text(Self.clock(playback.duration))
            Button(action: onResize) {
                CornerFrameIcon(inward: expanded)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(expanded ? "Achicar video" : "Agrandar video")
        }
        .font(.caption2.monospacedDigit())
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    static func clock(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return String(format: "%02d:%02d", (total / 60) % 100, total % 60)
    }
}

/// Mismas cuatro esquinas del control de agrandar.
struct CornerFrameIcon: View {
    var inward = false

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let arm = side * 0.34
            let weight = max(1.5, side * 0.1)
            let inset = weight
            let reach = inward ? side * 0.28 : 0
            let corners: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (inset, inset, 1, 1),
                (side - inset, inset, -1, 1),
                (inset, side - inset, 1, -1),
                (side - inset, side - inset, -1, -1),
            ]
            for (x, y, dx, dy) in corners {
                var path = Path()
                let originX = x + dx * reach
                let originY = y + dy * reach
                let dirX = inward ? -dx : dx
                let dirY = inward ? -dy : dy
                path.move(to: CGPoint(x: originX + dirX * arm, y: originY))
                path.addLine(to: CGPoint(x: originX, y: originY))
                path.addLine(to: CGPoint(x: originX, y: originY + dirY * arm))
                context.stroke(
                    path,
                    with: .color(.white),
                    style: StrokeStyle(lineWidth: weight, lineCap: .square, lineJoin: .miter)
                )
            }
        }
    }
}

/// El video ocupa toda la pantalla, con la misma X de las fotos.
struct ProjectVideoScreen: View {
    @ObservedObject var playback: ProjectVideoPlayback
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player = playback.player {
                ProjectVideoSurface(player: player)
                    .ignoresSafeArea()
            }
            ProjectVideoChrome(playback: playback, expanded: true, onResize: onClose)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.black.opacity(0.45)))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.trailing, 12)
            .accessibilityLabel("Cerrar")
        }
        .background(Color.black)
    }
}
