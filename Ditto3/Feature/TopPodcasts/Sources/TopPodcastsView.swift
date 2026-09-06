import Entity
import SwiftUI

struct TopPodcastsView: View {
  let state: TopPodcastsState
  let sendAction: (TopPodcastsAction) -> Void
  private let title = "TopPodcasts"

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        header
        switch state {
        case .none, .loading:
          loadingSection
        case .loaded(let podcasts):
          podcastsSection(podcasts)
        case .failed(let error):
          errorSection(message: error.localizedDescription)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 40)
    }
    .background(Color(uiColor: .systemBackground))
  }

  @ViewBuilder
  private func podcastsSection(_ podcasts: [Podcast]) -> some View {
    if podcasts.isEmpty {
      emptySection
    } else {
      ForEach(Array(podcasts.enumerated()), id: \.element.id) { index, podcast in
        Button {
          sendAction(.selectPodcast(podcast))
        } label: {
          PodcastRowView(
            podcast: podcast,
            rank: index + 1
          )
        }
        .buttonStyle(.plain)

        if index < podcasts.count - 1 {
          Divider()
            .padding(.leading, 104)
        }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Listen All")
        .font(.system(size: 44, weight: .bold, design: .rounded))
        .kerning(-1.4)

      Text(title)
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

  private var emptySection: some View {
    VStack(spacing: 12) {
      Image(systemName: "dot.radiowaves.left.and.right")
        .font(.title2)
        .foregroundStyle(.secondary)
      Text("No podcasts found.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
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

      VStack(alignment: .leading, spacing: 8) {
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
      }

      Spacer(minLength: 8)

      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.tertiary)
    }
    .contentShape(Rectangle())
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
    .frame(width: 84, height: 84)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private var rankLabel: String {
    "#\(rank) in Top Podcasts"
  }
}
