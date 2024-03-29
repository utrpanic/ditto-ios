import Foundation

public protocol HTTPNetwork {
  func get(with params: HTTPGetParams) async throws -> HTTPNetworkResponse
}

public enum HTTPNetworkError: Error {
  case malformedURL
  case httpError(Int)
}

public struct HTTPGetParams {
  
  public let url: URL?
  public let headers: [String: String]?
  public let queries: [String: Any]?
  
  public init(url: URL?, headers: [String: String]?, queries :[String: Any?]?) {
    self.url = url
    self.headers = headers
    self.queries = queries?.nilValueRemoved
  }
}

public struct HTTPNetworkResponse {
  
  public let body: Data
  
  public init(body: Data) {
    self.body = body
  }
}

private extension Dictionary where Key == String, Value == Any? {
  var nilValueRemoved: [String: Any] {
    var newDictionary = [String: Any]()
    self.forEach { key, value in
      guard let value = value else { return }
      newDictionary[key] = value
    }
    return newDictionary
  }
}
