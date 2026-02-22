import Core
import _Template

typealias Dependencies = _TemplateDependency

final class AppComponent: Dependencies, @unchecked Sendable {
  let _templateRepository: _TemplateRepository

  var _templateBuildable: _TemplateBuildable {
    _TemplateBuilder(dependency: self)
  }

  init() {
    _templateRepository = _TemplateRepositoryImp()
  }
}
