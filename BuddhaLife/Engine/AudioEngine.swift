import Foundation
import AVFoundation
import Observation

// MARK: - AudioEngine

/// Programmatic waveform-based sound engine using AVAudioEngine.
/// Faithfully ports audioEngine.js — generates sine/triangle tones with ADSR envelopes
/// for temple bells, chimes, merit/demerit sounds, and screen transitions.
///
/// Uses pre-rendered AVAudioPCMBuffers played through a pool of AVAudioPlayerNodes.
/// This avoids AVAudioSourceNode render-block closures that crash under Swift 6
/// strict concurrency (the render block runs on the audio IO thread, not @MainActor).
@MainActor @Observable
final class AudioEngine: NSObject {

    // MARK: - Singleton

    static let shared = AudioEngine()

    // MARK: - Public State

    /// Whether audio is muted. Persisted to UserDefaults.
    var isMuted: Bool {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: Self.muteKey)
        }
    }

    // MARK: - Private State

    private static let muteKey = "buddhalife_muted"

    private var engine: AVAudioEngine?
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayerIndex = 0
    private let playerCount = 4
    private let sampleRate: Double = 44100

    // Pre-rendered sound buffers
    private var bellBuffer: AVAudioPCMBuffer?
    private var chimeBuffer: AVAudioPCMBuffer?
    private var meritBuffer: AVAudioPCMBuffer?
    private var demeritBuffer: AVAudioPCMBuffer?
    private var transitionBuffer: AVAudioPCMBuffer?

    // MARK: - Init

    private override init() {
        isMuted = UserDefaults.standard.bool(forKey: Self.muteKey)
        super.init()
        setupAudioSession()
        setupEngine()
        prerenderBuffers()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: session
            )
        } catch {
            // Audio session setup failed -- sounds will be silent
        }
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            engine?.pause()
        case .ended:
            try? engine?.start()
        @unknown default:
            break
        }
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        let eng = AVAudioEngine()
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        // Create player node pool and attach/connect them once
        for _ in 0..<playerCount {
            let player = AVAudioPlayerNode()
            eng.attach(player)
            eng.connect(player, to: eng.mainMixerNode, format: format)
            players.append(player)
        }

        eng.mainMixerNode.outputVolume = 1.0
        eng.prepare()

        do {
            try eng.start()
        } catch {
            // Engine failed to start -- sounds will be silent
        }

        self.engine = eng
    }

    // MARK: - Tone Parameters

    private enum WaveformType {
        case sine
        case triangle
    }

    private struct ToneParams {
        var type: WaveformType = .sine
        var freq: Double
        var delay: Double = 0
        var attack: Double
        var decay: Double
        var sustain: Double = 0
        var release: Double = 0
        var peakGain: Double = 0.12
    }

    // MARK: - Buffer Pre-rendering

    /// Pre-render all sound effects into PCM buffers at init time.
    /// Each buffer contains the complete mixed waveform for one sound effect.
    private func prerenderBuffers() {
        bellBuffer = renderComposite([
            ToneParams(freq: 800, attack: 0.005, decay: 1.8, sustain: 0, release: 0.2, peakGain: 0.12),
            ToneParams(freq: 803, attack: 0.005, decay: 1.5, sustain: 0, release: 0.2, peakGain: 0.06),
            ToneParams(freq: 1600, attack: 0.003, decay: 0.8, sustain: 0, release: 0.1, peakGain: 0.03),
        ])

        chimeBuffer = renderComposite([
            ToneParams(freq: 1200, attack: 0.003, decay: 0.4, sustain: 0, release: 0.1, peakGain: 0.1),
            ToneParams(freq: 1802, attack: 0.003, decay: 0.25, sustain: 0, release: 0.05, peakGain: 0.04),
        ])

        meritBuffer = renderComposite([
            ToneParams(freq: 523, attack: 0.01, decay: 0.15, sustain: 0, release: 0.05, peakGain: 0.1),
            ToneParams(freq: 659, delay: 0.12, attack: 0.01, decay: 0.25, sustain: 0, release: 0.1, peakGain: 0.1),
        ])

        demeritBuffer = renderComposite([
            ToneParams(type: .triangle, freq: 220, attack: 0.02, decay: 0.4, sustain: 0, release: 0.15, peakGain: 0.08),
        ])

        let transitionNotes: [Double] = [440, 523, 659]
        let spacing = 0.1
        transitionBuffer = renderComposite(transitionNotes.enumerated().map { i, freq in
            ToneParams(freq: freq, delay: Double(i) * spacing, attack: 0.01, decay: 0.2, sustain: 0, release: 0.08, peakGain: 0.08)
        })
    }

    /// Render multiple tones mixed together into a single PCM buffer.
    private func renderComposite(_ tones: [ToneParams]) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return nil
        }

        // Find the total duration needed (max of delay + tone duration across all tones)
        let totalDuration = tones.map { $0.delay + $0.attack + $0.decay + $0.release + 0.05 }.max() ?? 1.0
        let frameCount = AVAudioFrameCount(totalDuration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let floatData = buffer.floatChannelData?[0] else { return nil }

        // Zero the buffer
        for i in 0..<Int(frameCount) {
            floatData[i] = 0
        }

        // Mix each tone into the buffer
        for params in tones {
            let delaySamples = Int(params.delay * sampleRate)
            let toneDuration = params.attack + params.decay + params.release + 0.05
            let toneSamples = Int(toneDuration * sampleRate)

            for i in 0..<toneSamples {
                let bufferIndex = delaySamples + i
                guard bufferIndex < Int(frameCount) else { break }

                let t = Double(i) / sampleRate
                let phase = params.freq * t

                // Waveform
                let sample: Double
                switch params.type {
                case .sine:
                    sample = sin(2.0 * .pi * phase)
                case .triangle:
                    let p = phase - floor(phase + 0.5)
                    sample = 4.0 * abs(p) - 1.0
                }

                // ADSR envelope
                let envGain: Double
                if t < params.attack {
                    envGain = params.peakGain * (t / params.attack)
                } else if t < params.attack + params.decay {
                    let decayProgress = (t - params.attack) / params.decay
                    envGain = params.peakGain - (params.peakGain * (1.0 - params.sustain)) * decayProgress
                } else if params.release > 0 && t < params.attack + params.decay + params.release {
                    let sustainGain = params.peakGain * params.sustain
                    let releaseProgress = (t - params.attack - params.decay) / params.release
                    envGain = sustainGain * (1.0 - releaseProgress)
                } else {
                    envGain = 0
                }

                floatData[bufferIndex] += Float(sample * envGain)
            }
        }

        return buffer
    }

    // MARK: - Playback

    /// Play a pre-rendered buffer on the next available player node.
    private func playBuffer(_ buffer: AVAudioPCMBuffer?) {
        guard !isMuted,
              let buffer,
              let engine,
              engine.isRunning else { return }

        let player = players[nextPlayerIndex % playerCount]
        nextPlayerIndex += 1

        player.stop()
        player.scheduleBuffer(buffer, completionHandler: nil)
        player.play()
    }

    // MARK: - Sound Effects

    /// Temple bell -- sine wave ~800Hz, quick attack, long shimmer decay (~2s).
    func playBell() {
        playBuffer(bellBuffer)
    }

    /// Light chime -- sine at ~1200Hz, short decay (~0.5s).
    func playChime() {
        playBuffer(chimeBuffer)
    }

    /// Pleasant ascending two-note tone for gaining merit.
    func playMeritSound() {
        playBuffer(meritBuffer)
    }

    /// Low subtle tone for gaining demerit.
    func playDemeritSound() {
        playBuffer(demeritBuffer)
    }

    /// Gentle 3-note ascending sequence for screen transitions.
    func playTransition() {
        playBuffer(transitionBuffer)
    }
}
