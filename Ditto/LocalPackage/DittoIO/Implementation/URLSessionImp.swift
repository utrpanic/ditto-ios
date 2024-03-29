import DittoIO
import Foundation

extension URLSession: URLSessionProtocol {
  public func data(_ request: URLRequest) async throws -> (Data, URLResponse) {
    return try await self.data(for: request)
  }
}
