import Entity

public protocol PlaybackSessionRepository: Sendable {
  func loadSession() async throws -> PlaybackSession?
  func saveSession(_ session: PlaybackSession) async throws
  func clearSession() async throws
}
