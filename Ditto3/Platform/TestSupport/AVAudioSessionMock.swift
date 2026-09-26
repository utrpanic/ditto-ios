import Platform

@MainActor
public final class AVAudioSessionMock: AVAudioSessionProtocol {
  public enum Error: Swift.Error {
    case activationFailed
  }

  public var shouldFail = false
  public private(set) var activationCallCount = 0

  public init() {}

  public func activatePlayback() throws {
    activationCallCount += 1
    if shouldFail { throw Error.activationFailed }
  }
}
