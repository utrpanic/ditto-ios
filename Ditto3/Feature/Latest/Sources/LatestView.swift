import Entity
import SwiftUI

struct LatestView: View {
  let state: LatestState
  let sendAction: (LatestAction) -> Void

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 0) {
        header

        switch state {
        case .loading:
          loadingSection
        case .loaded(let episodes, let failedPodcastCount):
          if failedPodcastCount > 0 {
            partialFailureSection(failedPodcastCount: failedPodcastCount)
          }
          episodesSection(episodes)
        case .failed(let message):
          errorSection(message: message)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 40)
    }
    .background(Color(uiColor: .systemBackground))
    .refreshable {
      sendAction(.refresh)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Latest")
        .font(.system(size: 44, weight: .bold, design: .rounded))
        .kerning(-1.4)

      Text("New episodes from followed podcasts")
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 20)
  }

  @ViewBuilder
  private func episodesSection(_ episodes: [Episode]) -> some View {
    if episodes.isEmpty {
      emptySection
    } else {
      ForEach(Array(episodes.enumerated()), id: \.element.id) { index, episode in
        Button {
          sendAction(.selectEpisode(episode))
        } label: {
          LatestEpisodeRow(episode: episode)
        }
        .buttonStyle(.plain)

        if index < episodes.count - 1 {
          Divider()
            .padding(.leading, 92)
        }
      }
    }
  }

  private var loadingSection: some View {
    VStack(spacing: 12) {
      ProgressView()
      Text("Loading latest episodes...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }

  private var emptySection: some View {
    VStack(spacing: 12) {
      Image(systemName: "sparkles")
        .font(.system(size: 32))
        .foregroundStyle(.secondary)

      Text("No Latest Episodes")
        .font(.headline)

      Text("New episodes from followed podcasts will appear here.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }

  private func partialFailureSection(failedPodcastCount: Int) -> some View {
    HStack(spacing: 10) {
      Image(systemName: "exclamationmark.triangle.fill")
      Text("Could not update \(failedPodcastCount) followed podcast\(failedPodcastCount == 1 ? "" : "s").")
        .font(.subheadline)
      Spacer(minLength: 8)
      Button("Retry") {
        sendAction(.refresh)
      }
      .font(.subheadline.weight(.semibold))
    }
    .foregroundStyle(.orange)
    .padding(12)
    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    .padding(.bottom, 8)
  }

  private func errorSection(message: String) -> some View {
    VStack(spacing: 12) {
      Image(systemName: "wifi.exclamationmark")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        sendAction(.refresh)
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }
}

private struct LatestEpisodeRow: View {
  let episode: Episode

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      artwork

      VStack(alignment: .leading, spacing: 6) {
        Text(episode.podcastTitle)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Text(episode.title)
          .font(.headline)
          .foregroundStyle(.primary)
          .lineLimit(3)

        if !metadata.isEmpty {
          Text(metadata)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
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
    AsyncImage(url: episode.artworkURL) { image in
      image
        .resizable()
        .scaledToFill()
    } placeholder: {
      ZStack {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(Color(uiColor: .secondarySystemBackground))

        Image(systemName: "waveform")
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 76, height: 76)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
