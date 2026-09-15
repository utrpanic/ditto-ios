import AVFoundation

@MainActor
public protocol AVAudioSessionProtocol: AnyObject {
  func activatePlayback() throws
}

extension AVAudioSession: AVAudioSessionProtocol {
  public func activatePlayback() throws {
    try setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay])
    try setActive(true)
  }
}
