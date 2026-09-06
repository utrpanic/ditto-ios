import Entity
import Foundation
import Platform
import PlatformTestSupport
@testable import RepositoryImp
import Testing

struct EpisodeRepositoryImpTests {
  @Test
  func fetchEpisodesMapsRSSItemsAndSortsNewestFirst() async throws {
    let session = URLSessionMock()
    session.stub(
      data: Data(
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
          <channel>
            <item>
              <title>Older Episode</title>
              <guid>older-guid</guid>
              <description><![CDATA[<p>An older description.</p>]]></description>
              <pubDate>Mon, 31 Aug 2026 09:00:00 +0000</pubDate>
              <itunes:duration>01:02:03</itunes:duration>
              <enclosure url="https://example.com/older.mp3" type="audio/mpeg" />
            </item>
            <item>
              <title>Newest Episode</title>
              <guid>newest-guid</guid>
              <itunes:author>Episode Author</itunes:author>
              <description>Newest description.</description>
              <pubDate>Tue, 01 Sep 2026 09:00:00 +0000</pubDate>
              <itunes:duration>42:30</itunes:duration>
              <itunes:image href="https://example.com/episode.png" />
              <link>https://example.com/newest</link>
              <enclosure url="https://example.com/newest.mp3" type="audio/mpeg" />
            </item>
          </channel>
        </rss>
        """.utf8
      ),
      response: makeHTTPURLResponse(url: "https://example.com/feed.xml", statusCode: 200)
    )
    let podcast = Podcast(
      id: PodcastID(42),
      title: "Architecture Talks",
      author: "KeepCast",
      artworkURL: URL(string: "https://example.com/podcast.png")
    )
    let feedURL = try #require(URL(string: "https://example.com/feed.xml"))
    let repository = EpisodeRepositoryImp(session: session)

    let episodes = try await repository.fetchEpisodes(
      podcast: podcast,
      feedURL: feedURL,
      limit: nil
    )

    #expect(session.lastRequest?.httpMethod == "GET")
    #expect(session.lastRequest?.url == feedURL)
    #expect(episodes.count == 2)

    let newest = episodes[0]
    #expect(newest.id == EpisodeID("newest-guid"))
    #expect(newest.podcastID == podcast.id)
    #expect(newest.podcastTitle == podcast.title)
    #expect(newest.title == "Newest Episode")
    #expect(newest.author == "Episode Author")
    #expect(newest.artworkURL == URL(string: "https://example.com/episode.png"))
    #expect(newest.audioURL == URL(string: "https://example.com/newest.mp3"))
    #expect(newest.pageURL == URL(string: "https://example.com/newest"))
    #expect(newest.description == "Newest description.")
    #expect(newest.duration == 2_550)

    let older = episodes[1]
    #expect(older.author == podcast.author)
    #expect(older.artworkURL == podcast.artworkURL)
    #expect(older.description == "An older description.")
    #expect(older.duration == 3_723)
  }

  @Test
  func fetchEpisodesAppliesLimitAfterSorting() async throws {
    let session = URLSessionMock()
    session.stub(
      data: Data(
        """
        <rss><channel>
          <item><title>Older</title><guid>older</guid><pubDate>Mon, 31 Aug 2026 09:00:00 +0000</pubDate></item>
          <item><title>Newer</title><guid>newer</guid><pubDate>Tue, 01 Sep 2026 09:00:00 +0000</pubDate></item>
        </channel></rss>
        """.utf8
      ),
      response: makeHTTPURLResponse(url: "https://example.com/feed.xml", statusCode: 200)
    )
    let podcast = Podcast(id: PodcastID(42), title: "Architecture Talks", author: "KeepCast")
    let feedURL = try #require(URL(string: "https://example.com/feed.xml"))
    let repository = EpisodeRepositoryImp(session: session)

    let episodes = try await repository.fetchEpisodes(
      podcast: podcast,
      feedURL: feedURL,
      limit: 1
    )

    #expect(episodes.map(\.title) == ["Newer"])
  }

  @Test
  func fetchEpisodesReturnsEmptyForNonpositiveLimitWithoutNetworkCall() async throws {
    let session = URLSessionMock()
    let podcast = Podcast(id: PodcastID(42), title: "Architecture Talks", author: "KeepCast")
    let feedURL = try #require(URL(string: "https://example.com/feed.xml"))
    let repository = EpisodeRepositoryImp(session: session)

    let episodes = try await repository.fetchEpisodes(
      podcast: podcast,
      feedURL: feedURL,
      limit: 0
    )

    #expect(episodes.isEmpty)
    #expect(session.callCount == 0)
  }
}
