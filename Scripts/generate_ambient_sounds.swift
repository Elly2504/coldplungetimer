#!/usr/bin/env swift

import AVFoundation
import Foundation

let sampleRate: Double = 44100
let duration: Double = 15.0
let totalSamples = Int(sampleRate * duration)

// MARK: - Helpers

func writeWAV(samples: [Float], to path: String) {
    let url = URL(fileURLWithPath: path)
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
        fatalError("Failed to create audio buffer")
    }
    buffer.frameLength = AVAudioFrameCount(samples.count)
    let channelData = buffer.floatChannelData![0]
    for i in 0..<samples.count {
        channelData[i] = samples[i]
    }

    do {
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        print("Generated: \(path)")
    } catch {
        fatalError("Failed to write \(path): \(error)")
    }
}

// Simple pseudo-random number generator (deterministic)
struct PRNG {
    var state: UInt64

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 33) / Double(UInt32.max)
    }

    mutating func nextFloat() -> Float {
        Float(next())
    }
}

// MARK: - Ocean Waves

func generateOcean() -> [Float] {
    var samples = [Float](repeating: 0, count: totalSamples)
    var prng = PRNG(state: 42)

    for i in 0..<totalSamples {
        let t = Double(i) / sampleRate

        // Pink-ish noise (sum of different frequency random walks)
        let noise = (prng.nextFloat() * 2 - 1) * 0.15

        // Slow wave swell envelope (~8 second cycle, smooth)
        let swell1 = Float(sin(2 * .pi * t / 8.0) * 0.5 + 0.5)
        let swell2 = Float(sin(2 * .pi * t / 12.0 + 1.5) * 0.3 + 0.5)
        let envelope = swell1 * 0.6 + swell2 * 0.4

        // Low frequency rumble (ocean base)
        let bass1 = Float(sin(2 * .pi * 55 * t)) * 0.08
        let bass2 = Float(sin(2 * .pi * 85 * t)) * 0.05
        let bass3 = Float(sin(2 * .pi * 35 * t)) * 0.06

        // Mid-frequency wash
        let mid1 = Float(sin(2 * .pi * 220 * t + sin(2 * .pi * 0.3 * t) * 2)) * 0.03
        let mid2 = Float(sin(2 * .pi * 330 * t + sin(2 * .pi * 0.2 * t) * 3)) * 0.02

        samples[i] = (noise * envelope + bass1 + bass2 + bass3 + (mid1 + mid2) * envelope) * 0.7
    }

    // Simple low-pass smoothing (moving average)
    var smoothed = [Float](repeating: 0, count: totalSamples)
    let windowSize = 8
    for i in 0..<totalSamples {
        var sum: Float = 0
        var count: Float = 0
        for j in max(0, i - windowSize)...min(totalSamples - 1, i + windowSize) {
            sum += samples[j]
            count += 1
        }
        smoothed[i] = sum / count
    }

    // Crossfade last 0.5s with first 0.5s for seamless loop
    let fadeLen = Int(sampleRate * 0.5)
    for i in 0..<fadeLen {
        let fade = Float(i) / Float(fadeLen)
        smoothed[totalSamples - fadeLen + i] = smoothed[totalSamples - fadeLen + i] * (1 - fade) + smoothed[i] * fade
    }

    return smoothed
}

// MARK: - Rain

func generateRain() -> [Float] {
    var samples = [Float](repeating: 0, count: totalSamples)
    var prng = PRNG(state: 123)

    for i in 0..<totalSamples {
        let t = Double(i) / sampleRate

        // White noise base
        let noise = (prng.nextFloat() * 2 - 1) * 0.18

        // Slight intensity variation (slow, subtle)
        let intensity = Float(sin(2 * .pi * t / 10.0) * 0.15 + 0.85)

        // Random "raindrop" plinks — occasional louder samples
        let dropChance = prng.next()
        let drop: Float = dropChance < 0.003 ? (prng.nextFloat() * 0.3 + 0.1) * (prng.next() > 0.5 ? 1 : -1) : 0

        // Gentle high-frequency texture
        let hiss = Float(sin(2 * .pi * 3500 * t + Double(prng.nextFloat()) * .pi)) * 0.02

        samples[i] = (noise * intensity + drop + hiss) * 0.6
    }

    // Band-pass effect: low-pass smoothing
    var smoothed = [Float](repeating: 0, count: totalSamples)
    let windowSize = 3
    for i in 0..<totalSamples {
        var sum: Float = 0
        var count: Float = 0
        for j in max(0, i - windowSize)...min(totalSamples - 1, i + windowSize) {
            sum += samples[j]
            count += 1
        }
        smoothed[i] = sum / count
    }

    // Crossfade for seamless loop
    let fadeLen = Int(sampleRate * 0.5)
    for i in 0..<fadeLen {
        let fade = Float(i) / Float(fadeLen)
        smoothed[totalSamples - fadeLen + i] = smoothed[totalSamples - fadeLen + i] * (1 - fade) + smoothed[i] * fade
    }

    return smoothed
}

// MARK: - Generate

let oceanSamples = generateOcean()
writeWAV(samples: oceanSamples, to: "IceDip/Resources/Sounds/ocean.wav")

let rainSamples = generateRain()
writeWAV(samples: rainSamples, to: "IceDip/Resources/Sounds/rain.wav")

print("Ambient sound generation complete!")
