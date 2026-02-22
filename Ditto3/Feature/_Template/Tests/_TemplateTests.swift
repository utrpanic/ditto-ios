import Testing
@testable import _Template

struct _TemplateTests {
  @Test func smoke() async throws {
    _ = _TemplateModule.coreMarker()
  }
}
