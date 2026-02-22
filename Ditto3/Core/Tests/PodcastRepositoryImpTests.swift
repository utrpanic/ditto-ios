import Foundation
import Testing
import Platform
import PlatformTestSupport
@testable import Core

struct PodcastRepositoryImpTests {
  @Test
  func searchPodcastsReturnsEmptyForBlankQueryWithoutNetworkCall() async throws {
    let session = URLSessionMock()
    let repository = PodcastRepositoryImp(session: session)

    let result = try await repository.searchPodcasts(query: "  \n\t ")

    #expect(result.isEmpty)
    #expect(session.callCount == 0)
  }

  @Test
  func searchPodcastsBuildsRequestAndMapsResults() async throws {
    let session = URLSessionMock()
    session.stub(
      data: Data(
        """
        {
          "results": [
            {
              "collectionId": 1,
              "collectionName": "Swift Talk",
              "artistName": "Apple",
              "artworkUrl600": "https://example.com/600.png",
              "feedUrl": "https://example.com/feed.xml",
              "description": "Desc"
            },
            {
              "collectionId": 2,
              "collectionName": "Fallback Art",
              "artistName": "Team",
              "artworkUrl100": "https://example.com/100.png"
            },
            {
              "collectionName": "Invalid Missing ID",
              "artistName": "Nobody"
            }
          ]
        }
        """.utf8
      ),
      response: makeHTTPURLResponse(url: "https://itunes.apple.com/search", statusCode: 200)
    )
    let repository = PodcastRepositoryImp(session: session)

    let podcasts = try await repository.searchPodcasts(query: "  swift podcast  ")

    #expect(session.callCount == 1)
    #expect(session.lastRequest?.httpMethod == "GET")
    #expect(session.lastRequest?.url?.host == "itunes.apple.com")
    #expect(session.lastRequest?.url?.path == "/search")

    let queryItems = URLComponents(url: try #require(session.lastRequest?.url), resolvingAgainstBaseURL: false)?.queryItems
    #expect(queryItems?.first(where: { $0.name == "term" })?.value == "swift podcast")
    #expect(queryItems?.first(where: { $0.name == "media" })?.value == "podcast")
    #expect(queryItems?.first(where: { $0.name == "entity" })?.value == "podcast")
    #expect(queryItems?.first(where: { $0.name == "limit" })?.value == "50")

    #expect(podcasts.count == 2)
    #expect(podcasts[0] == Podcast(
      id: PodcastID(1),
      title: "Swift Talk",
      author: "Apple",
      artworkURL: URL(string: "https://example.com/600.png"),
      feedURL: URL(string: "https://example.com/feed.xml"),
      summary: "Desc"
    ))
    #expect(podcasts[1] == Podcast(
      id: PodcastID(2),
      title: "Fallback Art",
      author: "Team",
      artworkURL: URL(string: "https://example.com/100.png"),
      feedURL: nil,
      summary: nil
    ))
  }

  @Test
  func searchPodcastsThrowsForNon2xxResponse() async {
    let session = URLSessionMock()
    session.stub(
      data: Data("{}".utf8),
      response: makeHTTPURLResponse(url: "https://itunes.apple.com/search", statusCode: 500)
    )
    let repository = PodcastRepositoryImp(session: session)

    var didThrow = false

    do {
      _ = try await repository.searchPodcasts(query: "swift")
    } catch let error as PodcastRepositoryImpError {
      didThrow = true
      switch error {
      case .httpStatus(let code):
        #expect(code == 500)
      default:
        #expect(Bool(false))
      }
    } catch {
      didThrow = true
      #expect(Bool(false))
    }

    #expect(didThrow)
  }

  @Test
  func fetchTopPodcastsClampsLimitToValidRangeAndMapsResults() async throws {
    let session = URLSessionMock()
    session.stub(
      data: Data(
        """
        {
          "feed": {
            "results": [
              {
                "id": "10",
                "name": "Top One",
                "artistName": "Artist",
                "artworkUrl100": "https://example.com/top100.png"
              },
              {
                "id": "11",
                "name": "Top Two",
                "artistName": "Artist 2",
                "artworkUrl60": "https://example.com/top60.png"
              },
              {
                "id": "invalid",
                "name": "Ignored",
                "artistName": "Ignored"
              }
            ]
          }
        }
        """.utf8
      ),
      response: makeHTTPURLResponse(url: "https://rss.applemarketingtools.com/api/v2/us/podcasts/top/100/podcasts.json", statusCode: 200)
    )
    let repository = PodcastRepositoryImp(session: session)

    let podcasts = try await repository.fetchTopPodcasts(limit: 999)

    #expect(session.callCount == 1)
    #expect(session.lastRequest?.httpMethod == "GET")
    #expect(session.lastRequest?.url?.absoluteString == "https://rss.applemarketingtools.com/api/v2/us/podcasts/top/100/podcasts.json")
    #expect(podcasts.count == 2)
    #expect(podcasts[0] == Podcast(
      id: PodcastID(10),
      title: "Top One",
      author: "Artist",
      artworkURL: URL(string: "https://example.com/top100.png"),
      feedURL: nil,
      summary: nil
    ))
    #expect(podcasts[1] == Podcast(
      id: PodcastID(11),
      title: "Top Two",
      author: "Artist 2",
      artworkURL: URL(string: "https://example.com/top60.png"),
      feedURL: nil,
      summary: nil
    ))
  }

  @Test
  func fetchTopPodcastsClampsMinimumLimitToOne() async throws {
    let session = URLSessionMock()
    session.stub(
      data: Data(#"{"feed":{"results":[]}}"#.utf8),
      response: makeHTTPURLResponse(url: "https://rss.applemarketingtools.com/api/v2/us/podcasts/top/1/podcasts.json", statusCode: 200)
    )
    let repository = PodcastRepositoryImp(session: session)

    let podcasts = try await repository.fetchTopPodcasts(limit: 0)

    #expect(podcasts.isEmpty)
    #expect(session.lastRequest?.url?.absoluteString == "https://rss.applemarketingtools.com/api/v2/us/podcasts/top/1/podcasts.json")
  }
}
