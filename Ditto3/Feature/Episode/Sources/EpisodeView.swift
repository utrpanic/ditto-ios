import Entity
import SwiftUI

struct EpisodeView: View {
  let state: EpisodeState
  let sendAction: (EpisodeAction) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        artwork
          .frame(maxWidth: .infinity)

        titleSection
        metadataSection
        playbackActions

        if let queueMessage = state.queueMessage {
          Text(queueMessage)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }

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

  private var playbackActions: some View {
    HStack(spacing: 0) {
      Button {
        sendAction(.play)
      } label: {
        Label(
          episode.audioURL == nil ? "Unavailable" : "Play",
          systemImage: "play.fill"
        )
        .frame(maxWidth: .infinity)
        .frame(height: 50)
      }
      .buttonStyle(.plain)

      Divider()
        .overlay(.white.opacity(0.35))
        .frame(height: 28)

      Menu {
        Button("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward") {
          sendAction(.playNext)
        }

        Button("Add to Queue", systemImage: "text.badge.plus") {
          sendAction(.addToQueue)
        }
      } label: {
        Image(systemName: "chevron.down")
          .font(.subheadline.weight(.bold))
          .frame(width: 52)
          .frame(height: 50)
      }
      .accessibilityLabel("Queue Options")
    }
    .font(.headline)
    .foregroundStyle(.white)
    .background(.tint)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .disabled(episode.audioURL == nil)
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
