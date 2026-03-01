import Foundation
import AVFoundation
import Observation

// MARK: - AudioEngine

/// Programmatic waveform-based sound engine using AVAudioEngine.
/// Faithfully ports audioEngine.js — generates sine/triangle tones with ADSR envelopes
/// for temple bells, chimes, merit/demerit sounds, and screen transitions.
@MainActor @Observable
final class AudioEngine {

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
    private var isEngineRunning = false
    private let sampleRate: Double = 44100

    // MARK: - Init

    private init() {
        isMuted = UserDefaults.standard.bool(forKey: Self.muteKey)
        setupAudioSession()
        setupEngine()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)

            // Handle interruptions gracefully
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
            isEngineRunning = false
        case .ended:
            // Try to restart the engine
            setupEngine()
        @unknown default:
            break
        }
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        engine = AVAudioEngine()
        guard let engine else { return }

        // Connect a dummy mixer node to keep the engine graph valid.
        // We attach source nodes on-the-fly for each sound.
        let mainMixer = engine.mainMixerNode
        mainMixer.outputVolume = 1.0

        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            isEngineRunning = false
        }
    }

    /// Ensure the engine is running and audio is not muted.
    private func ensureReady() -> Bool {
        guard !isMuted else { return false }
        guard let engine else { return false }

        if !isEngineRunning {
            do {
                try engine.start()
                isEngineRunning = true
            } catch {
                return false
            }
        }
        return true
    }

    // MARK: - Tone Generation

    /// Waveform type matching the JS oscillator types.
    private enum WaveformType {
        case sine
        case triangle
    }

    /// ADSR envelope parameters matching createTone from audioEngine.js.
    private struct ToneParams {
        var type: WaveformType = .sine
        var freq: Double
        var delay: Double = 0          // delay from "now" before this tone starts
        var attack: Double
        var decay: Double
        var sustain: Double = 0        // sustain level (0-1 of peakGain)
        var release: Double = 0
        var peakGain: Double = 0.12
    }

    /// Schedule a tone as a short-lived AVAudioSourceNode.
    /// The node renders samples for the full ADSR envelope then detaches itself.
    private func playTone(_ params: ToneParams) {
        guard ensureReady(), let engine else { return }

        let sampleRate = self.sampleRate
        let freq = params.freq
        let attack = params.attack
        let decay = params.decay
        let sustain = params.sustain
        let release = params.release
        let peakGain = params.peakGain
        let waveformType = params.type
        let delaySeconds = params.delay

        let totalDuration = attack + decay + release + 0.05
        let totalSamples = Int(totalDuration * sampleRate)
        let delaySamples = Int(delaySeconds * sampleRate)

        var sampleIndex = -delaySamples // start negative to count through delay

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        let sourceNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let buffer = ablPointer[0]
            let frames = Int(frameCount)
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            for frame in 0..<frames {
                let idx = sampleIndex + frame

                // During delay, output silence
                if idx < 0 {
                    data[frame] = 0
                    continue
                }

                // Past the end of the tone, output silence
                if idx >= totalSamples {
                    data[frame] = 0
                    continue
                }

                let t = Double(idx) / sampleRate
                let phase = freq * t

                // Generate waveform sample
                let sample: Double
                switch waveformType {
                case .sine:
                    sample = sin(2.0 * .pi * phase)
                case .triangle:
                    // Triangle wave: 2 * |2 * (t*f - floor(t*f + 0.5))| - 1
                    let p = phase - floor(phase + 0.5)
                    sample = 4.0 * abs(p) - 1.0
                }

                // Calculate envelope gain at time t
                let envGain: Double
                if t < attack {
                    // Attack: ramp from ~0 to peakGain
                    envGain = peakGain * (t / attack)
                } else if t < attack + decay {
                    // Decay: ramp from peakGain to sustain level
                    let decayProgress = (t - attack) / decay
                    envGain = peakGain - (peakGain * (1.0 - sustain)) * decayProgress
                } else if release > 0 && t < attack + decay + release {
                    // Release: ramp from sustain level to ~0
                    let sustainGain = peakGain * sustain
                    let releaseProgress = (t - attack - decay) / release
                    envGain = sustainGain * (1.0 - releaseProgress)
                } else {
                    envGain = 0
                }

                data[frame] = Float(sample * envGain)
            }

            sampleIndex += frames
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)

        // Schedule cleanup after the tone completes
        let cleanupDelay = delaySeconds + totalDuration + 0.1
        Task { @MainActor [weak engine] in
            try? await Task.sleep(nanoseconds: UInt64(cleanupDelay * 1_000_000_000))
            guard let engine else { return }
            engine.disconnectNodeOutput(sourceNode)
            engine.detach(sourceNode)
        }
    }

    // MARK: - Sound Effects

    /// Temple bell -- sine wave ~800Hz, quick attack, long shimmer decay (~2s).
    /// Played on: age advance, festival events.
    /// Matches playBell from audioEngine.js.
    func playBell() {
        // Main bell tone
        playTone(ToneParams(
            freq: 800,
            attack: 0.005,
            decay: 1.8,
            sustain: 0,
            release: 0.2,
            peakGain: 0.12
        ))

        // Shimmer overtone (slight frequency offset for beating)
        playTone(ToneParams(
            freq: 803,
            attack: 0.005,
            decay: 1.5,
            sustain: 0,
            release: 0.2,
            peakGain: 0.06
        ))

        // Higher harmonic for brightness
        playTone(ToneParams(
            freq: 1600,
            attack: 0.003,
            decay: 0.8,
            sustain: 0,
            release: 0.1,
            peakGain: 0.03
        ))
    }

    /// Light chime -- sine at ~1200Hz, short decay (~0.5s).
    /// Played on: making a choice.
    /// Matches playChime from audioEngine.js.
    func playChime() {
        playTone(ToneParams(
            freq: 1200,
            attack: 0.003,
            decay: 0.4,
            sustain: 0,
            release: 0.1,
            peakGain: 0.1
        ))

        // Soft overtone
        playTone(ToneParams(
            freq: 1802,
            attack: 0.003,
            decay: 0.25,
            sustain: 0,
            release: 0.05,
            peakGain: 0.04
        ))
    }

    /// Pleasant ascending two-note tone for gaining merit.
    /// Matches playMeritSound from audioEngine.js.
    func playMeritSound() {
        // First note -- C5
        playTone(ToneParams(
            freq: 523,
            attack: 0.01,
            decay: 0.15,
            sustain: 0,
            release: 0.05,
            peakGain: 0.1
        ))

        // Second note -- E5 (ascending major third), delayed by 120ms
        playTone(ToneParams(
            freq: 659,
            delay: 0.12,
            attack: 0.01,
            decay: 0.25,
            sustain: 0,
            release: 0.1,
            peakGain: 0.1
        ))
    }

    /// Low subtle tone for gaining demerit.
    /// Matches playDemeritSound from audioEngine.js.
    func playDemeritSound() {
        playTone(ToneParams(
            type: .triangle,
            freq: 220,
            attack: 0.02,
            decay: 0.4,
            sustain: 0,
            release: 0.15,
            peakGain: 0.08
        ))
    }

    /// Gentle 3-note ascending sequence for screen transitions.
    /// Matches playTransition from audioEngine.js.
    func playTransition() {
        let notes: [Double] = [440, 523, 659] // A4, C5, E5
        let spacing = 0.1

        for (i, freq) in notes.enumerated() {
            playTone(ToneParams(
                freq: freq,
                delay: Double(i) * spacing,
                attack: 0.01,
                decay: 0.2,
                sustain: 0,
                release: 0.08,
                peakGain: 0.08
            ))
        }
    }
}
