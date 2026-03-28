public protocol Buildable {}

open class Builder<Dependency>: Buildable {
  public let dependency: Dependency
  public init(dependency: Dependency) {
    self.dependency = dependency
  }
}
