import Foundation
import Platform

public final class URLSessionMock: URLSessionProtocol, @unchecked Sendable {
  public private(set) var callCount = 0
  public private(set) var lastRequest: URLRequest?
  private var result: Result<(Data, URLResponse), Error> = .failure(StubError.unstubbed)

  public init() {}

  public func stub(data: Data, response: URLResponse) {
    result = .success((data, response))
  }

  public func stub(error: Error) {
    result = .failure(error)
  }

  public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    callCount += 1
    lastRequest = request
    return try result.get()
  }

  private enum StubError: Error {
    case unstubbed
  }
}
