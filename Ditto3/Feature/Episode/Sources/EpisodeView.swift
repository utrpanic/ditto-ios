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
        keepSection

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

  private var keepSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button {
        sendAction(.toggleKeep)
      } label: {
        HStack(spacing: 10) {
          keepIcon
          Text(keepButtonTitle)
            .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .foregroundStyle(keepForegroundColor)
        .background(keepBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
      .buttonStyle(.plain)
      .disabled(state.isKept == nil || state.isUpdatingKeep)

      if let message = state.keepErrorMessage {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(message)
            .font(.caption)
            .foregroundStyle(.red)

          Spacer()

          Button("Retry") {
            sendAction(.retryKeepState)
          }
          .font(.caption.weight(.semibold))
        }
      }
    }
  }

  @ViewBuilder
  private var keepIcon: some View {
    if state.isUpdatingKeep || (state.isKept == nil && state.keepErrorMessage == nil) {
      ProgressView()
        .tint(keepForegroundColor)
    } else {
      Image(systemName: keepIconName)
    }
  }

  private var keepButtonTitle: String {
    if state.isKept == nil {
      return state.keepErrorMessage == nil ? "Loading Keep Status" : "Keep Unavailable"
    }
    return state.isKept == true ? "Kept" : "Keep"
  }

  private var keepIconName: String {
    if state.isKept == nil { return "exclamationmark.triangle" }
    return state.isKept == true ? "bookmark.fill" : "bookmark"
  }

  private var keepForegroundColor: Color {
    state.isKept == true ? .white : .accentColor
  }

  private var keepBackgroundColor: Color {
    state.isKept == true ? .accentColor : Color(uiColor: .secondarySystemBackground)
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
