import AVFoundation

@MainActor
protocol AudioSessionControlling: AnyObject {
  func activatePlayback() throws
}

@MainActor
final class AVAudioSessionAdapter: AudioSessionControlling {
  func activatePlayback() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay])
    try session.setActive(true)
  }
}
