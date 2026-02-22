import Foundation

public func makeHTTPURLResponse(url: String, statusCode: Int) -> HTTPURLResponse {
  HTTPURLResponse(
    url: URL(string: url)!,
    statusCode: statusCode,
    httpVersion: nil,
    headerFields: nil
  )!
}
