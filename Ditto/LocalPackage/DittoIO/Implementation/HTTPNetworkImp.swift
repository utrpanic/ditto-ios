import Foundation
import DittoIO

enum HTTPMethod: String {
  case get = "GET"
}

public final class HTTPNetworkImp: HTTPNetwork {
  private let session: URLSessionProtocol

  public init(session: URLSessionProtocol) {
    self.session = session
  }

  public func get(with params: HTTPGetParams) async throws -> HTTPNetworkResponse {
    guard let url = params.url,
          var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      throw HTTPNetworkError.malformedURL
    }
    urlComponents.queryItems = params.queries?.map {
      return URLQueryItem(name: $0.key, value: String(describing: $0.value))
    }
    guard let urlWithQuery = urlComponents.url else {
      throw HTTPNetworkError.malformedURL
    }
    var request = URLRequest(url: urlWithQuery)
    request.allHTTPHeaderFields = params.headers
    request.httpMethod = HTTPMethod.get.rawValue
    let (data, _) = try await self.session.data(request)
    return HTTPNetworkResponse(body: data)
  }
}
