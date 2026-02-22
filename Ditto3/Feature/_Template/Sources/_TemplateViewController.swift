import SwiftUI
import UIKit

@MainActor
final class _TemplateViewController: UIHostingController<AnyView>, _TemplatePresentable {
  private let retainables: [AnyObject]

  init<Content: View>(rootView: Content, retainables: [AnyObject] = []) {
    self.retainables = retainables
    super.init(rootView: AnyView(rootView))
  }

  @available(*, unavailable)
  required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
