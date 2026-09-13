import Entity
import SwiftUI

struct EpisodeView: View {
  let state: EpisodeState

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        artwork
          .frame(maxWidth: .infinity)

        titleSection
        metadataSection

        if let description = episode.description, !description.isEmpty {
          Divider()
          Text(description)
            .font(.body)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
    }
    .background(Color(uiColor: .systemBackground))
    .navigationTitle("Episode")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var episode: Episode {
    state.episode
  }

  private var artwork: some View {
    AsyncImage(url: episode.artworkURL) { image in
      image
        .resizable()
        .scaledToFill()
    } placeholder: {
      ZStack {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(Color(uiColor: .secondarySystemBackground))

        Image(systemName: "waveform")
          .font(.system(size: 48, weight: .semibold))
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 240, height: 240)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
  }

  private var titleSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(episode.title)
        .font(.system(size: 32, weight: .bold, design: .rounded))

      Text(episode.podcastTitle)
        .font(.title3.weight(.semibold))
        .foregroundStyle(.secondary)

      if let author = episode.author, !author.isEmpty {
        Text(author)
          .font(.subheadline)
          .foregroundStyle(.tertiary)
      }
    }
  }

  @ViewBuilder
  private var metadataSection: some View {
    if episode.publishedAt != nil || episode.duration != nil {
      HStack(spacing: 16) {
        if let publishedAt = episode.publishedAt {
          Label(publishedAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
        }

        if let duration = episode.duration {
          Label(durationText(duration), systemImage: "clock")
        }
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
    }
  }

  private func durationText(_ duration: TimeInterval) -> String {
    let totalMinutes = max(Int(duration) / 60, 0)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    if hours > 0 {
      return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }

    return "\(minutes)m"
  }
}
