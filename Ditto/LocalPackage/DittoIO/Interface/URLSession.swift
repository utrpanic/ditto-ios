import Foundation

public protocol URLSessionProtocol {
  func data(_ request: URLRequest) async throws -> (Data, URLResponse)
}
