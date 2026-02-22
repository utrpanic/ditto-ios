import SwiftUI
import UIKit

struct _TemplateView<Interactor: _TemplateInteractable>: View {
  @ObservedObject var interactor: Interactor

  var body: some View {
    VStack(spacing: 16) {
      Text(interactor.state.title)
        .font(.title2.weight(.medium))

      Text("count: \(interactor.state.count)")
        .font(.body.monospacedDigit())

      Button("Count Up") {
        interactor.didTapCountUp()
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemBackground))
  }
}

//#Preview {
//  _TemplateView(interactor: _TemplateInteractor(dependency: PreviewDependency()))
//}
//
//private struct PreviewDependency: _TemplateDependency {
//  let _templateRepository: _TemplateRepository = _TemplateRepositoryImp()
//}
