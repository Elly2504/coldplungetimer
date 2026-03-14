import AVFoundation

@MainActor
@Observable
final class AmbientSoundService {
    private var audioPlayer: AVAudioPlayer?
    var playbackFailed = false

    func play(sound: AmbientSound) {
        stop()
        playbackFailed = false
        configureAudioSession()
        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "wav") else {
            playbackFailed = true
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            playbackFailed = true
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
