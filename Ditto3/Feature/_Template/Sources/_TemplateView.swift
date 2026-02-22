import SwiftUI
import UIKit

struct _TemplateView: View {
  var body: some View {
    Text("_Template")
      .font(.title2.weight(.medium))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(uiColor: .systemBackground))
  }
}

#Preview {
  _TemplateView()
}
