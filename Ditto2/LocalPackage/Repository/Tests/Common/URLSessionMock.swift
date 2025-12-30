import Foundation
import Repository

final class URLSessionMock: URLSessionProtocol, @unchecked Sendable {
  private var mockResponses: [String: (Data, URLResponse)] = [:]
  private var errorForURL: [String: Error] = [:]

  func setMockResponse(for path: String, data: Data, statusCode: Int = 200) {
    let url = URL(string: "https://dapi.kakao.com\(path)")!
    let response = HTTPURLResponse(
      url: url,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: nil
    )!
    mockResponses[path] = (data, response)
  }

  func setError(for path: String, error: Error) {
    errorForURL[path] = error
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    guard let url = request.url else {
      throw URLError(.badURL)
    }

    let path = url.path + (url.query.map { "?\($0)" } ?? "")

    if let error = errorForURL[path] {
      throw error
    }

    // Try to match with query parameters
    for (mockPath, response) in mockResponses {
      if path.hasPrefix(mockPath) || mockPath.hasPrefix(url.path) {
        return response
      }
    }

    throw URLError(.badServerResponse)
  }
}

// MARK: - Mock Response Builders

extension URLSessionMock {
  static func createBlogSearchMockResponse(
    searchText: String = "카카오뱅크",
    page: Int = 1,
    size: Int = 10,
    isEnd: Bool = false
  ) -> Data {
    let documents = (1...size).map { index in
      """
      {
        "title": "Blog Post \(index) about \(searchText)",
        "contents": "This is the content of blog post \(index)",
        "url": "https://example.com/blog/\(index)",
        "blogname": "Test Blog \(index)",
        "thumbnail": "https://example.com/thumb/\(index).jpg",
        "datetime": "2025-12-\(String(format: "%02d", index))T10:00:00.000+09:00"
      }
      """
    }

    let json = """
    {
      "meta": {
        "total_count": 100,
        "pageable_count": 80,
        "is_end": \(isEnd)
      },
      "documents": [\(documents.joined(separator: ","))]
    }
    """

    return json.data(using: .utf8)!
  }

  static func createImageSearchMockResponse(
    searchText: String = "카카오뱅크",
    page: Int = 1,
    size: Int = 10,
    isEnd: Bool = false
  ) -> Data {
    let documents = (1...size).map { index in
      """
      {
        "collection": "blog",
        "thumbnail_url": "https://example.com/thumb/\(index).jpg",
        "image_url": "https://example.com/image/\(index).jpg",
        "width": 400,
        "height": 300,
        "display_sitename": "Test Site \(index)",
        "doc_url": "https://example.com/doc/\(index)",
        "datetime": "2025-12-\(String(format: "%02d", index))T10:00:00.000+09:00"
      }
      """
    }

    let json = """
    {
      "meta": {
        "total_count": 100,
        "pageable_count": 80,
        "is_end": \(isEnd)
      },
      "documents": [\(documents.joined(separator: ","))]
    }
    """

    return json.data(using: .utf8)!
  }

  static func createVideoSearchMockResponse(
    searchText: String = "카카오뱅크",
    page: Int = 1,
    size: Int = 10,
    isEnd: Bool = false
  ) -> Data {
    let documents = (1...size).map { index in
      """
      {
        "title": "Video \(index) about \(searchText)",
        "url": "https://example.com/video/\(index)",
        "datetime": "2025-12-\(String(format: "%02d", index))T10:00:00.000+09:00",
        "play_time": \(120 + index * 10),
        "thumbnail": "https://example.com/thumb/\(index).jpg",
        "author": "Author \(index)"
      }
      """
    }

    let json = """
    {
      "meta": {
        "total_count": 100,
        "pageable_count": 80,
        "is_end": \(isEnd)
      },
      "documents": [\(documents.joined(separator: ","))]
    }
    """

    return json.data(using: .utf8)!
  }
}
