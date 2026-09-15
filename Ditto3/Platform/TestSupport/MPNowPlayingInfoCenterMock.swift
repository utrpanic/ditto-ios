import Foundation
import Platform

@MainActor
public final class MPNowPlayingInfoCenterMock: MPNowPlayingInfoCenterProtocol {
  public struct Update: Equatable {
    public let title: String?
    public let podcastTitle: String?
    public let duration: TimeInterval?
    public let position: TimeInterval?
    public let isPlaying: Bool
  }

  public private(set) var updates: [Update] = []

  public init() {}

  public func update(
    title: String?,
    podcastTitle: String?,
    duration: TimeInterval?,
    position: TimeInterval?,
    isPlaying: Bool
  ) {
    updates.append(Update(
      title: title,
      podcastTitle: podcastTitle,
      duration: duration,
      position: position,
      isPlaying: isPlaying
    ))
  }
}
