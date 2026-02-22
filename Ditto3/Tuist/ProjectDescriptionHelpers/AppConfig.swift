import ProjectDescription

public enum AppConfig {
  public static let projectName = "Ditto3"
  public static let displayName = "Ditto3"
  public static let bundlePrefix = "com.example.ditto3"

  public static func bundleId(_ suffix: String) -> String {
    "\(bundlePrefix).\(suffix)"
  }
}
