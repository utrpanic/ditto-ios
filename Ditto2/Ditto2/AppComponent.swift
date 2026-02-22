import Feature
import FeatureImp
import Repository
import RepositoryImp

typealias Dependencies = _TemplateDependency

final class AppComponent: Dependencies {
  let _templateRepository: _TemplateRepository

  var _templateBuildable: _TemplateBuildable { _TemplateBuilder(dependency: self) }

  init() {
    self._templateRepository = _TemplateRepositoryImp()
  }
}
