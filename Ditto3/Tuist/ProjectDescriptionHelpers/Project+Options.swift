import ProjectDescription

public extension Project.Options {
  static let `default` = Self.options(
    textSettings: .textSettings(
      usesTabs: false,
      indentWidth: 2,
      tabWidth: 2
    )
  )
}
