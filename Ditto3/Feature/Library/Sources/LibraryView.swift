import Entity
import SwiftUI

struct LibraryView: View {
  let state: LibraryState
  let sendAction: (LibraryAction) -> Void

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 0) {
        header

        switch state {
        case .loading:
          loadingSection
        case .loaded(let followedPodcasts):
          podcastsSection(followedPodcasts)
        case .failed(let message):
          errorSection(message: message)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 40)
    }
    .background(Color(uiColor: .systemBackground))
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Library")
        .font(.system(size: 44, weight: .bold, design: .rounded))
        .kerning(-1.4)

      Text("Followed Podcasts")
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 20)
  }

  @ViewBuilder
  private func podcastsSection(_ followedPodcasts: [FollowedPodcast]) -> some View {
    if followedPodcasts.isEmpty {
      emptySection
    } else {
      ForEach(Array(followedPodcasts.enumerated()), id: \.element.podcast.id) { index, followedPodcast in
        Button {
          sendAction(.selectPodcast(followedPodcast.podcast))
        } label: {
          LibraryPodcastRow(followedPodcast: followedPodcast)
        }
        .buttonStyle(.plain)

        if index < followedPodcasts.count - 1 {
          Divider()
            .padding(.leading, 96)
        }
      }
    }
  }

  private var loadingSection: some View {
    VStack(spacing: 12) {
      ProgressView()
      Text("Loading followed podcasts...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }

  private var emptySection: some View {
    VStack(spacing: 12) {
      Image(systemName: "rectangle.stack.badge.plus")
        .font(.system(size: 32))
        .foregroundStyle(.secondary)

      Text("No Followed Podcasts")
        .font(.headline)

      Text("Podcasts you follow will appear here.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }

  private func errorSection(message: String) -> some View {
    VStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        sendAction(.retry)
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }
}

private struct LibraryPodcastRow: View {
  let followedPodcast: FollowedPodcast

  var body: some View {
    HStack(spacing: 16) {
      artwork

      VStack(alignment: .leading, spacing: 6) {
        Text(followedPodcast.podcast.title)
          .font(.headline)
          .foregroundStyle(.primary)
          .lineLimit(2)

        Text(followedPodcast.podcast.author)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Text("Followed \(followedPodcast.followedAt.formatted(date: .abbreviated, time: .omitted))")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.tertiary)
    }
    .contentShape(Rectangle())
    .padding(.vertical, 14)
  }

  private var artwork: some View {
    AsyncImage(url: followedPodcast.podcast.artworkURL) { image in
      image
        .resizable()
        .scaledToFill()
    } placeholder: {
      ZStack {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color(uiColor: .secondarySystemBackground))

        Image(systemName: "dot.radiowaves.left.and.right")
          .font(.system(size: 26, weight: .semibold))
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 76, height: 76)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }
}
