import Core
import SwiftUI

struct TopPodcastsView: View {
  @ObservedObject var stateStore: TopPodcastsViewStateStore

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        header

        if stateStore.state.isLoading && stateStore.state.items.isEmpty {
          loadingSection
        } else if let errorMessage = stateStore.state.errorMessage {
          errorSection(message: errorMessage)
        } else {
          ForEach(Array(stateStore.state.items.enumerated()), id: \.element.id) { index, podcast in
            PodcastRowView(
              podcast: podcast,
              rank: index + 1
            )

            if index < stateStore.state.items.count - 1 {
              Divider()
                .padding(.leading, 116)
            }
          }
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
      Text("Listen All")
        .font(.system(size: 44, weight: .bold, design: .rounded))
        .kerning(-1.4)

      Text(stateStore.state.title)
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 20)
  }

  private var loadingSection: some View {
    VStack(spacing: 16) {
      ProgressView()
      Text("Loading top podcasts...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
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
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
  }
}

private struct PodcastRowView: View {
  let podcast: Podcast
  let rank: Int

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      artwork

      VStack(alignment: .leading, spacing: 10) {
        Text(rankLabel)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)

        Text(podcast.title)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(.primary)
          .lineLimit(2)

        Text(podcast.author)
          .font(.system(size: 17, weight: .regular))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        HStack {
          durationPill
          Spacer()
          rowActions
        }
      }
    }
    .padding(.vertical, 18)
  }

  private var artwork: some View {
    AsyncImage(url: podcast.artworkURL) { image in
      image
        .resizable()
        .scaledToFill()
    } placeholder: {
      ZStack {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(
            LinearGradient(
              colors: [Color(red: 1.0, green: 0.3, blue: 0.48), Color(red: 0.52, green: 0.28, blue: 1.0)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )

        Image(systemName: "waveform")
          .font(.system(size: 28, weight: .semibold))
          .foregroundStyle(.white.opacity(0.9))
      }
    }
    .frame(width: 96, height: 96)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private var durationPill: some View {
    HStack(spacing: 10) {
      Image(systemName: "play.fill")
        .font(.system(size: 14, weight: .bold))
      Text(durationLabel)
        .font(.system(size: 17, weight: .semibold))
    }
    .foregroundStyle(Color(red: 0.44, green: 0.19, blue: 0.95))
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(
      Capsule(style: .continuous)
        .fill(Color(uiColor: .secondarySystemBackground))
    )
  }

  private var rowActions: some View {
    HStack(spacing: 16) {
      Image(systemName: "arrow.down.circle")
      Image(systemName: "ellipsis")
    }
    .font(.system(size: 20, weight: .medium))
    .foregroundStyle(.tertiary)
  }

  private var rankLabel: String {
    "#\(rank) in Top Podcasts"
  }

  private var durationLabel: String {
    // TODO: Replace this placeholder duration once episode-level runtime data is available.
    let minutes = 18 + (rank * 7 % 42)
    if minutes >= 60 {
      let hours = minutes / 60
      let remainingMinutes = minutes % 60
      return remainingMinutes == 0 ? "\(hours)h" : "\(hours)h \(remainingMinutes)m"
    }

    return "\(minutes)m"
  }
}
