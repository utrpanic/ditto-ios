import Entity
import Foundation
import SwiftUI

struct PlayerView: View {
  let state: PlayerState
  let sendAction: (PlayerAction) -> Void

  var body: some View {
    Group {
      if let session = state.session {
        miniPlayer(session: session)
      } else {
        Color.clear
      }
    }
    .sheet(isPresented: expandedBinding) {
      if let session = state.session {
        ExpandedPlayerView(
          state: state,
          session: session,
          sendAction: sendAction
        )
        .presentationDragIndicator(.visible)
      }
    }
  }

  private var expandedBinding: Binding<Bool> {
    Binding(
      get: { state.isExpanded },
      set: { isPresented in
        sendAction(isPresented ? .presentExpanded : .dismissExpanded)
      }
    )
  }

  private func miniPlayer(session: PlaybackSession) -> some View {
    HStack(spacing: 12) {
      artwork(url: session.episode.artworkURL, size: 48, cornerRadius: 10)

      Button {
        sendAction(.presentExpanded)
      } label: {
        VStack(alignment: .leading, spacing: 3) {
          Text(session.episode.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)

          Text(session.episode.podcastTitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      playbackButton(size: 18)
    }
    .padding(.horizontal, 12)
    .frame(height: PlayerViewController.miniPlayerHeight)
    .background(.ultraThinMaterial)
    .overlay(alignment: .top) {
      Divider()
    }
  }

  private func playbackButton(size: CGFloat) -> some View {
    Button {
      sendAction(.togglePlayback)
    } label: {
      Group {
        if state.isLoading {
          ProgressView()
        } else {
          Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: size, weight: .semibold))
        }
      }
      .frame(width: 44, height: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(state.isLoading)
    .accessibilityLabel(state.isPlaying ? "Pause" : "Play")
  }

  private func artwork(
    url: URL?,
    size: CGFloat,
    cornerRadius: CGFloat
  ) -> some View {
    AsyncImage(url: url) { image in
      image
        .resizable()
        .scaledToFill()
    } placeholder: {
      ZStack {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .fill(Color(uiColor: .secondarySystemBackground))
        Image(systemName: "waveform")
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
  }
}

private struct ExpandedPlayerView: View {
  let state: PlayerState
  let session: PlaybackSession
  let sendAction: (PlayerAction) -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 28) {
        header
        artwork
        metadata
        progress
        controls

        if let message = state.failureMessage {
          Text(message)
            .font(.subheadline)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }
      }
      .padding(.horizontal, 28)
      .padding(.vertical, 24)
    }
    .background(Color(uiColor: .systemBackground))
  }

  private var header: some View {
    HStack {
      Button {
        sendAction(.dismissExpanded)
      } label: {
        Image(systemName: "chevron.down")
          .font(.headline)
          .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Dismiss Player")

      Spacer()

      Text("Now Playing")
        .font(.headline)

      Spacer()

      Color.clear.frame(width: 44, height: 44)
    }
  }

  private var artwork: some View {
    AsyncImage(url: session.episode.artworkURL) { image in
      image
        .resizable()
        .scaledToFill()
    } placeholder: {
      ZStack {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(Color(uiColor: .secondarySystemBackground))
        Image(systemName: "waveform")
          .font(.system(size: 54, weight: .semibold))
          .foregroundStyle(.secondary)
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
  }

  private var metadata: some View {
    VStack(spacing: 8) {
      Text(session.episode.title)
        .font(.title2.bold())
        .multilineTextAlignment(.center)

      Text(session.episode.podcastTitle)
        .font(.headline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }

  private var progress: some View {
    VStack(spacing: 8) {
      Slider(value: positionBinding, in: 0...duration)
        .disabled(duration == 0)

      HStack {
        Text(formattedTime(session.position))
        Spacer()
        Text("-\(formattedTime(max(duration - session.position, 0)))")
      }
      .font(.caption.monospacedDigit())
      .foregroundStyle(.secondary)
    }
  }

  private var controls: some View {
    HStack(spacing: 42) {
      Button {
        sendAction(.skipBackward)
      } label: {
        Image(systemName: "gobackward.15")
          .font(.system(size: 30))
      }
      .accessibilityLabel("Skip Back 15 Seconds")

      Button {
        sendAction(.togglePlayback)
      } label: {
        Group {
          if state.isLoading {
            ProgressView()
              .controlSize(.large)
          } else {
            Image(systemName: state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
              .font(.system(size: 68))
          }
        }
        .frame(width: 76, height: 76)
      }
      .disabled(state.isLoading)
      .accessibilityLabel(state.isPlaying ? "Pause" : "Play")

      Button {
        sendAction(.skipForward)
      } label: {
        Image(systemName: "goforward.30")
          .font(.system(size: 30))
      }
      .accessibilityLabel("Skip Forward 30 Seconds")
    }
    .buttonStyle(.plain)
  }

  private var positionBinding: Binding<Double> {
    Binding(
      get: { min(max(session.position, 0), duration) },
      set: { sendAction(.seek(to: $0)) }
    )
  }

  private var duration: TimeInterval {
    guard let duration = session.episode.duration,
          duration.isFinite,
          duration > 0 else {
      return 0
    }
    return duration
  }

  private func formattedTime(_ time: TimeInterval) -> String {
    let totalSeconds = max(Int(time), 0)
    let hours = totalSeconds / 3_600
    let minutes = (totalSeconds % 3_600) / 60
    let seconds = totalSeconds % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
  }
}
