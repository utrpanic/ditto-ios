import Foundation
import DittoIO
import DittoIOImp

final class URLSessionMock: URLSessionProtocol {
  
  private(set) var request: URLRequest?
  private var response: HTTPNetworkResponse
  
  init(response: HTTPNetworkResponse) {
    self.response = response
  }
  
  func data(_ request: URLRequest) async throws -> (Data, URLResponse) {
    self.request = request
    
    return (self.response.body, URLResponse())
  }
}
