import Core

struct TopPodcastsState {
  var title = "TopPodcasts"
  var limit = 20
  var isLoading = false
  var items: [Podcast] = []
  var errorMessage: String?
}
