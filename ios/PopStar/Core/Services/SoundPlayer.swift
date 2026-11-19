import AVFoundation
import Foundation

enum SoundEffect
{
    case select
    case pop(count: Int)
    case stageCleared
}

@MainActor
protocol SoundPlaying
{
    func play(_ effect: SoundEffect)
    func setMuted(_ isMuted: Bool)
}

/// Erzeugt kleine Chiptune-artige Effekte zur Laufzeit mit `AVAudioEngine` –
/// ohne Audiodateien. Vorbild sind die Töne der Web-Version.
@MainActor
final class SoundPlayer: SoundPlaying
{
    private enum Config
    {
        static let sampleRate = 44_100.0
        static let attackDuration = 0.012
        static let decayRate = 4.5
    }

    private enum Waveform
    {
        case sine
        case triangle

        func sample(atPhase phase: Double) -> Double
        {
            switch self
            {
            case .sine:
                return sin(phase)
            case .triangle:
                let cycle = (phase / (2 * .pi)).truncatingRemainder(dividingBy: 1)
                return 2 * abs(2 * cycle - 1) - 1
            }
        }
    }

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var format: AVAudioFormat?
    private var isMuted = false

    func setMuted(_ isMuted: Bool)
    {
        self.isMuted = isMuted
    }

    func play(_ effect: SoundEffect)
    {
        guard !isMuted, let node = activateAudioGraph() else { return }

        switch effect
        {
        case .select:
            scheduleTone(frequency: 520, duration: 0.07, volume: 0.35, glide: 1.15, wave: .sine, on: node)

        case .pop(let count):
            let base = 300.0 + Double(min(count, 20)) * 26.0
            scheduleTone(frequency: base, duration: 0.12, volume: 0.6, glide: 1.7, wave: .triangle, on: node)
            scheduleTone(frequency: base * 1.5, duration: 0.16, volume: 0.3, glide: 1.4, wave: .sine, on: node, delay: 0.02)
            if count >= 8
            {
                scheduleTone(frequency: base * 2, duration: 0.2, volume: 0.25, glide: 1.2, wave: .sine, on: node, delay: 0.06)
            }

        case .stageCleared:
            let notes = [523.25, 659.25, 783.99, 1046.5]
            for (index, note) in notes.enumerated()
            {
                scheduleTone(
                    frequency: note,
                    duration: 0.22,
                    volume: 0.45,
                    glide: 1.0,
                    wave: .triangle,
                    on: node,
                    delay: Double(index) * 0.09
                )
            }
        }
    }

    // MARK: - Audio-Aufbau

    private func activateAudioGraph() -> AVAudioPlayerNode?
    {
        if audioEngine == nil
        {
            guard let format = AVAudioFormat(standardFormatWithSampleRate: Config.sampleRate, channels: 1) else { return nil }
            let engine = AVAudioEngine()
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            audioEngine = engine
            playerNode = node
            self.format = format
        }

        guard let engine = audioEngine else { return nil }
        if !engine.isRunning
        {
            do
            {
                try engine.start()
            }
            catch
            {
                return nil
            }
        }
        return playerNode
    }

    // MARK: - Klang-Erzeugung

    private func scheduleTone(
        frequency: Double,
        duration: Double,
        volume: Double,
        glide: Double,
        wave: Waveform,
        on node: AVAudioPlayerNode,
        delay: Double = 0
    )
    {
        guard let buffer = toneBuffer(
            frequency: frequency,
            duration: duration,
            volume: volume,
            glide: glide,
            wave: wave,
            delay: delay
        )
        else { return }
        node.scheduleBuffer(buffer)
    }

    /// Füllt einen Puffer mit leading silence, Attack, exponentiellem Decay
    /// und optionalem Frequenz-Glide.
    private func toneBuffer(
        frequency: Double,
        duration: Double,
        volume: Double,
        glide: Double,
        wave: Waveform,
        delay: Double
    ) -> AVAudioPCMBuffer?
    {
        guard let format else { return nil }
        let leadSamples = Int(delay * format.sampleRate)
        let toneSamples = Int(duration * format.sampleRate)
        let totalSamples = leadSamples + toneSamples
        guard totalSamples > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples)),
              let channelData = buffer.floatChannelData
        else { return nil }

        buffer.frameLength = AVAudioFrameCount(totalSamples)
        let attackSamples = Double(min(toneSamples, Int(Config.attackDuration * format.sampleRate)))

        for index in 0..<totalSamples
        {
            guard index >= leadSamples else
            {
                channelData[0][index] = 0
                continue
            }
            let elapsed = Double(index - leadSamples)
            let time = elapsed / format.sampleRate
            let progress = elapsed / Double(toneSamples)

            let frequencyAtTime = frequency * pow(glide, progress)
            let sample = wave.sample(atPhase: 2 * .pi * frequencyAtTime * time)
            let attack = attackSamples > 0 ? min(1, elapsed / attackSamples) : 1
            let decay = exp(-Config.decayRate * progress)

            channelData[0][index] = Float(sample * volume * attack * decay)
        }
        return buffer
    }
}
