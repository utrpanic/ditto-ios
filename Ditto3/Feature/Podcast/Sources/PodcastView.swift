import Entity
import SwiftUI

struct PodcastView: View {
  let state: PodcastState
  let sendAction: (PodcastAction) -> Void

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        podcastHeader

        if let summary = podcast.summary, !summary.isEmpty {
          Text(summary)
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Divider()

        episodesSection
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
    }
    .background(Color(uiColor: .systemBackground))
    .navigationTitle("Podcast")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var podcast: Podcast {
    state.podcast
  }

  private var podcastHeader: some View {
    HStack(alignment: .top, spacing: 18) {
      artwork

      VStack(alignment: .leading, spacing: 10) {
        Text(podcast.title)
          .font(.system(size: 28, weight: .bold, design: .rounded))
          .fixedSize(horizontal: false, vertical: true)

        Text(podcast.author)
          .font(.headline)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var artwork: some View {
    AsyncImage(url: podcast.artworkURL) { image in
      image
        .resizable()
        .scaledToFill()
    } placeholder: {
      ZStack {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(Color(uiColor: .secondarySystemBackground))

        Image(systemName: "dot.radiowaves.left.and.right")
          .font(.system(size: 36, weight: .semibold))
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 116, height: 116)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
  }

  @ViewBuilder
  private var episodesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Latest Episodes")
        .font(.title2.bold())

      switch state {
      case .loading:
        loadingSection
      case .loaded(_, let episodes):
        if episodes.isEmpty {
          emptySection
        } else {
          episodeRows(episodes)
        }
      case .failed(_, let message):
        errorSection(message: message)
      }
    }
  }

  private var loadingSection: some View {
    HStack(spacing: 12) {
      ProgressView()
      Text("Loading latest episodes...")
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 24)
  }

  private var emptySection: some View {
    VStack(spacing: 10) {
      Image(systemName: "waveform")
        .font(.title2)
        .foregroundStyle(.secondary)
      Text("No Episodes")
        .font(.headline)
      Text("This podcast has no episodes to display.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
  }

  private func errorSection(message: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Button("Retry") {
        sendAction(.retry)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(.vertical, 16)
  }

  private func episodeRows(_ episodes: [Episode]) -> some View {
    ForEach(Array(episodes.enumerated()), id: \.element.id) { index, episode in
      Button {
        sendAction(.selectEpisode(episode))
      } label: {
        PodcastEpisodeRow(episode: episode)
      }
      .buttonStyle(.plain)

      if index < episodes.count - 1 {
        Divider()
      }
    }
  }
}

private struct PodcastEpisodeRow: View {
  let episode: Episode

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        Text(episode.title)
          .font(.headline)
          .foregroundStyle(.primary)
          .lineLimit(3)

        if !metadata.isEmpty {
          Text(metadata)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if let description = episode.description, !description.isEmpty {
          Text(description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.tertiary)
    }
    .contentShape(Rectangle())
    .padding(.vertical, 10)
  }

  private var metadata: String {
    [publishedText, durationText].compactMap { $0 }.joined(separator: " · ")
  }

  private var publishedText: String? {
    episode.publishedAt?.formatted(date: .abbreviated, time: .omitted)
  }

  private var durationText: String? {
    guard let duration = episode.duration else { return nil }
    let totalMinutes = max(Int(duration) / 60, 0)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 {
      return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
    return "\(minutes)m"
  }
}
