import Entity
import SwiftUI

struct SearchView: View {
  @ObservedObject var store: SearchStateStore
  private let interactor: SearchInteractable
  @State private var query = ""

  init(store: SearchStateStore, interactor: SearchInteractable) {
    self.store = store
    self.interactor = interactor
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        header

        switch store.state {
        case .idle:
          idleSection
        case .loading(let query):
          loadingSection(query: query)
        case .loaded(_, let podcasts):
          podcastsSection(podcasts)
        case .failed(_, let message):
          errorSection(message: message)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 40)
    }
    .background(Color(uiColor: .systemBackground))
    .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search podcasts")
    .onSubmit(of: .search) {
      interactor.sendAction(.search(query))
    }
    .onChange(of: query) { _, newValue in
      if newValue.isEmpty {
        interactor.sendAction(.clear)
      }
    }
  }

  @ViewBuilder
  private func podcastsSection(_ podcasts: [Podcast]) -> some View {
    if podcasts.isEmpty {
      emptySection
    } else {
      ForEach(Array(podcasts.enumerated()), id: \.element.id) { index, podcast in
        Button {
          interactor.sendAction(.selectPodcast(podcast))
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

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Search")
        .font(.system(size: 44, weight: .bold, design: .rounded))

      Text("Find podcasts by title, author, or keyword.")
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 20)
  }

  private var idleSection: some View {
    VStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.title2)
        .foregroundStyle(.secondary)

      Text("Enter a search term to find podcasts.")
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

      Button("Retry") {
        interactor.sendAction(.search(query))
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
  }
}

private struct SearchPodcastRowView: View {
  let podcast: Podcast

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      artwork

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

  private var artwork: some View {
    AsyncImage(url: podcast.artworkURL) { image in
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
}
