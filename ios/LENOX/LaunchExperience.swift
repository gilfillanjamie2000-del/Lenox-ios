import AVFoundation
import Combine
import CryptoKit
import SwiftUI
import UIKit

enum ApprovedAssets {
    static let introHash = "85f30b59c4287db67d4123961bf3e77c22dae340d449e97845c5078eefece668"
    static let heroHash = "4a09a937f442b1d246b0f352f40f9e0bc4036ef37bb8d3d1ad4aeb0784564221"
    static func url(_ name: String) -> URL? { Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "ApprovedAssets") }
    static func verified(_ url: URL, hash: String, limit: Int) -> Bool {
        guard url.isFileURL, let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size > 0, size <= limit, let bytes = try? Data(contentsOf: url, options: .mappedIfSafe) else { return false }
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined() == hash
    }
    static let hero: UIImage? = {
        guard let url = url("lenox-android-hero.png"), verified(url, hash: heroHash, limit: 400_000) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }()
}

@MainActor final class IntroPlayer: ObservableObject {
    @Published private(set) var finished = false
    @Published private(set) var player: AVPlayer?
    @Published private(set) var muted = true
    private var gate = IntroGate()
    private var observations = Set<AnyCancellable>()
    private var startup: Task<Void, Never>?
    private var timeout: Task<Void, Never>?
    private var began = false

    func start(reduceMotion: Bool) {
        guard !began, !finished else { return }; began = true
        var bypass = false
        #if targetEnvironment(simulator)
        let args = ProcessInfo.processInfo.arguments
        bypass = args.contains(where: { $0.hasPrefix("--ci-") }) && !args.contains("--ci-intro")
        if args.contains("--ci-intro-missing") { finish("missing"); return }
        #endif
        guard !reduceMotion, !bypass, let url = ApprovedAssets.url("lenox-intro.mp4") else { finish(reduceMotion ? "reduce-motion" : "bypassed-or-missing"); return }
        // The timeout includes hash validation and first-frame preparation.
        timeout = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 15_000_000_000) } catch { return }
            self?.finish("timeout")
        }
        startup = Task { [weak self] in
            let valid = await Task.detached(priority: .userInitiated) {
                ApprovedAssets.verified(url, hash: ApprovedAssets.introHash, limit: 2_300_000)
            }.value
            guard let self, !Task.isCancelled, !self.finished else { return }
            guard self.gate.begin(reduceMotion: false, assetValid: valid) else { self.finish("checksum-failure"); return }
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.isMuted = self.muted
            self.player = player
            item.publisher(for: \.status).receive(on: DispatchQueue.main).sink { [weak self] status in
                if status == .failed { self?.finish("decode-failure") }
            }.store(in: &self.observations)
            for name in [AVPlayerItem.didPlayToEndTimeNotification, AVPlayerItem.failedToPlayToEndTimeNotification] {
                NotificationCenter.default.publisher(for: name, object: item).receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in self?.finish(name == AVPlayerItem.didPlayToEndTimeNotification ? "completed" : "playback-failure") }.store(in: &self.observations)
            }
            NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification).receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.finish("interrupted") }.store(in: &self.observations)
            player.play()
        }
    }
    func toggleSound() { guard !finished else { return }; muted.toggle(); player?.isMuted = muted }
    func finish(_ reason: String = "skipped") {
        guard !finished else { return }
        gate.finish(); finished = true
        startup?.cancel(); timeout?.cancel()
        player?.pause(); player?.replaceCurrentItem(with: nil); player = nil
        observations.removeAll()
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--ci-intro") {
            let report: [String: Any] = ["reason": reason, "source": Bundle.main.object(forInfoDictionaryKey: "LENOXSourceCommit") as? String ?? "unknown", "physical_device_tested": false]
            let file = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("intro-result.json")
            if let bytes = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]) { try? bytes.write(to: file, options: .atomic) }
        }
        #endif
    }
}

struct LaunchExperience: View {
    @EnvironmentObject private var audio: AudioModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var intro = IntroPlayer()
    var body: some View {
        GeometryReader { window in
          ZStack {
            // The audio/library owner lives above the launch presentation.
            StudioView().opacity(intro.finished ? 1 : 0)
                .allowsHitTesting(intro.finished).accessibilityHidden(!intro.finished)
            if !intro.finished {
                ZStack {
                    Color.black.ignoresSafeArea()
                    if let player = intro.player { IntroSurface(player: player).ignoresSafeArea().accessibilityHidden(true) }
                    VStack {
                        Spacer()
                        HStack(spacing: 20) {
                            Button { intro.toggleSound() } label: {
                                Label(intro.muted ? "Sound off" : "Sound on", systemImage: intro.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            }.accessibilityIdentifier("intro-sound")
                            Spacer()
                            Button("Skip intro") { intro.finish() }.accessibilityIdentifier("intro-skip")
                        }.font(.headline).buttonStyle(.borderedProminent).tint(.black.opacity(0.75)).padding(20)
                    }
                }
            }
          }.frame(width: window.size.width, height: window.size.height)
        }
        .task { intro.start(reduceMotion: reduceMotion) }
        .onChange(of: reduceMotion) { if $0 { intro.finish("reduce-motion") } }
        .onChange(of: scenePhase) { phase in
            // Leaving the foreground finishes the one-shot intro. It never resumes
            // over live decks, and navigation never creates another intro player.
            if phase != .active { intro.finish("background") }
        }
    }
}

private struct IntroSurface: UIViewRepresentable {
    final class Surface: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
    let player: AVPlayer
    func makeUIView(context: Context) -> Surface {
        let view = Surface(); view.backgroundColor = .black
        view.playerLayer.videoGravity = .resizeAspect; view.playerLayer.player = player
        return view
    }
    func updateUIView(_ uiView: Surface, context: Context) { uiView.playerLayer.player = player }
    static func dismantleUIView(_ uiView: Surface, coordinator: ()) { uiView.playerLayer.player = nil }
}
