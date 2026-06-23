import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Reads challenge prompts aloud for children who can't read yet (ages 3-5).
@MainActor
public final class ChallengeSpeaker {
    public static let shared = ChallengeSpeaker()

    #if canImport(AVFoundation)
    private let synthesizer = AVSpeechSynthesizer()
    #endif

    public init() {}

    public func speak(_ text: String) {
        #if canImport(AVFoundation)
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.05
        synthesizer.speak(utterance)
        #endif
    }

    public func stop() {
        #if canImport(AVFoundation)
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        #endif
    }
}
