import SwiftUI
import UIKit

struct _TemplateView: View {
  let state: _TemplateState
  let sendAction: (_TemplateAction) -> Void

  var body: some View {
    VStack(spacing: 16) {
      Text(state.title)
        .font(.title2.weight(.medium))

      Text("count: \(state.count)")
        .font(.body.monospacedDigit())

      Button("Count Up") {
        sendAction(.countUp)
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemBackground))
  }
}

#Preview {
  _TemplateView(state: _TemplateState(), sendAction: { _ in })
}
