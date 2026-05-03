import Foundation

public struct YINDetector: PitchDetectionAlgorithm {
    public let sampleRate: Double
    public let bufferSize: Int
    public let threshold: Float
    public let minFrequency: Float
    public let maxFrequency: Float

    public init(
        sampleRate: Double = 44100,
        bufferSize: Int = 2048,
        threshold: Float = 0.15,
        minFrequency: Float = 60,
        maxFrequency: Float = 2000
    ) {
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
        self.threshold = threshold
        self.minFrequency = minFrequency
        self.maxFrequency = maxFrequency
    }

    public func detectPitch(
        in samples: UnsafePointer<Float>,
        count: Int
    ) -> (frequency: Float, confidence: Float)? {
        let maxLag = count / 2
        guard maxLag > 2 else { return nil }

        let minLag = max(2, Int(sampleRate / Double(maxFrequency)))
        let upperLag = min(maxLag, Int(sampleRate / Double(minFrequency)))
        guard minLag < upperLag else { return nil }

        // Stage 1: difference function d(τ) = Σ (x[j] - x[j+τ])²
        var d = [Float](repeating: 0, count: maxLag)
        for tau in 1..<maxLag {
            var sum: Float = 0
            let limit = count - tau
            var j = 0
            while j < limit {
                let diff = samples[j] - samples[j + tau]
                sum += diff * diff
                j += 1
            }
            d[tau] = sum
        }

        // Stage 2: cumulative mean normalized difference d'(τ)
        var dPrime = [Float](repeating: 1, count: maxLag)
        var runningSum: Float = 0
        for tau in 1..<maxLag {
            runningSum += d[tau]
            if runningSum > 0 {
                dPrime[tau] = d[tau] * Float(tau) / runningSum
            } else {
                dPrime[tau] = 1
            }
        }

        // Stage 3: absolute threshold — first local minimum in [minLag, upperLag] below threshold
        var chosen: Int? = nil
        var tau = minLag
        while tau < upperLag - 1 {
            if dPrime[tau] < threshold {
                while tau + 1 < upperLag && dPrime[tau + 1] < dPrime[tau] {
                    tau += 1
                }
                chosen = tau
                break
            }
            tau += 1
        }

        // Stage 4: fallback to global minimum if no sub-threshold dip found
        if chosen == nil {
            var bestTau = minLag
            var bestVal = dPrime[minLag]
            for t in (minLag + 1)..<upperLag {
                if dPrime[t] < bestVal {
                    bestVal = dPrime[t]
                    bestTau = t
                }
            }
            if bestVal > 0.5 {
                return nil
            }
            chosen = bestTau
        }

        guard let tauChosen = chosen, tauChosen > 0, tauChosen < maxLag - 1 else {
            return nil
        }

        // Stage 5: parabolic interpolation around the chosen lag
        let s0 = dPrime[tauChosen - 1]
        let s1 = dPrime[tauChosen]
        let s2 = dPrime[tauChosen + 1]
        let denom = s0 - 2 * s1 + s2
        let betterTau: Float
        if abs(denom) > 1e-9 {
            betterTau = Float(tauChosen) + 0.5 * (s0 - s2) / denom
        } else {
            betterTau = Float(tauChosen)
        }

        guard betterTau > 0 else { return nil }
        let frequency = Float(sampleRate) / betterTau
        guard frequency >= minFrequency, frequency <= maxFrequency else { return nil }

        let confidence = max(0, min(1, 1 - s1))
        return (frequency, confidence)
    }
}
