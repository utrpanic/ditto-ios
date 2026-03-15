@testable import _Template
import Repository
import RepositoryImp
import Testing

struct _TemplateTests {
  @MainActor
  @Test func smoke() async throws {
    let builder = _TemplateBuilder(dependency: Dependency())
    _ = builder.build(listener: nil)
  }
}

private struct Dependency: _TemplateDependency {
  let _templateRepository: _TemplateRepository = _TemplateRepositoryImp()
}
