import Entity
import Foundation
import SwiftUI

struct SearchView: View {
  let state: SearchState
  let sendAction: (SearchAction) -> Void

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        header
        tabPicker

        switch state.result {
        case .idle:
          idleSection
        case .loading(let query):
          loadingSection(query: query)
        case .podcasts(let podcasts):
          podcastsSection(podcasts)
        case .episodes(let episodes):
          episodesSection(episodes)
        case .failed(let query, let message):
          errorSection(query: query, message: message)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 40)
    }
    .background(Color(uiColor: .systemBackground))
    .searchable(
      text: queryBinding,
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: state.selectedTab == .podcast ? "Search podcasts" : "Search episodes"
    )
    .onSubmit(of: .search) {
      sendAction(.submitSearch)
    }
  }

  private var queryBinding: Binding<String> {
    Binding(
      get: { state.query },
      set: { sendAction(.updateQuery($0)) }
    )
  }

  private var tabBinding: Binding<SearchTab> {
    Binding(
      get: { state.selectedTab },
      set: { sendAction(.selectTab($0)) }
    )
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Search")
        .font(.system(size: 44, weight: .bold, design: .rounded))

      Text("Find podcasts and individual episodes.")
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 20)
  }

  private var tabPicker: some View {
    Picker("Search type", selection: tabBinding) {
      ForEach(SearchTab.allCases) { tab in
        Text(tab.rawValue).tag(tab)
      }
    }
    .pickerStyle(.segmented)
    .padding(.bottom, 16)
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
          SearchPodcastRowView(podcast: podcast)
        }
        .buttonStyle(.plain)

        if index < podcasts.count - 1 {
          Divider()
            .padding(.leading, 92)
        }
      }
    }
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
          SearchEpisodeRowView(episode: episode)
        }
        .buttonStyle(.plain)

        if index < episodes.count - 1 {
          Divider()
            .padding(.leading, 92)
        }
      }
    }
  }

  private var idleSection: some View {
    VStack(spacing: 12) {
      Image(systemName: state.selectedTab == .podcast ? "dot.radiowaves.left.and.right" : "waveform")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text(state.selectedTab == .podcast
        ? "Enter a search term to find podcasts."
        : "Enter a search term to find episodes.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
  }

  private func loadingSection(query: String) -> some View {
    VStack(spacing: 16) {
      ProgressView()
      Text("Searching for \"\(query)\"...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
  }

  private var emptySection: some View {
    VStack(spacing: 12) {
      Image(systemName: "questionmark.folder")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text(state.selectedTab == .podcast ? "No podcasts found." : "No episodes found.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
  }

  private func errorSection(query: String, message: String) -> some View {
    VStack(spacing: 12) {
      Image(systemName: "wifi.exclamationmark")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        sendAction(.submitSearch)
      }
      .buttonStyle(.borderedProminent)
      .accessibilityHint("Search again for \(query)")
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
  }
}

private struct SearchPodcastRowView: View {
  let podcast: Podcast

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      SearchArtworkView(url: podcast.artworkURL, systemImage: "dot.radiowaves.left.and.right")

      VStack(alignment: .leading, spacing: 8) {
        Text(podcast.title)
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(.primary)
          .lineLimit(2)

        Text(podcast.author)
          .font(.system(size: 16, weight: .regular))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        if let summary = podcast.summary, !summary.isEmpty {
          Text(summary)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, 16)
  }
}

private struct SearchEpisodeRowView: View {
  let episode: Episode

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      SearchArtworkView(url: episode.artworkURL, systemImage: "waveform")

      VStack(alignment: .leading, spacing: 7) {
        Text(episode.title)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(.primary)
          .lineLimit(3)

        Text(episode.podcastTitle)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        if !metadata.isEmpty {
          Text(metadata)
            .font(.caption)
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
    }
    .padding(.vertical, 16)
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

private struct SearchArtworkView: View {
  let url: URL?
  let systemImage: String

  var body: some View {
    AsyncImage(url: url) { image in
      image
        .resizable()
        .scaledToFill()
    } placeholder: {
      ZStack {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(Color(uiColor: .secondarySystemBackground))

        Image(systemName: systemImage)
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 76, height: 76)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}
