import AVFoundation

@MainActor
@Observable
final class AmbientSoundService {
    private var audioPlayer: AVAudioPlayer?

    func play(sound: AmbientSound) {
        stop()
        configureAudioSession()
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "wav") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            print("Ambient sound error: \(error)")
        }
    }

    func pause() {
        audioPlayer?.pause()
    }

    func resume() {
        audioPlayer?.play()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
