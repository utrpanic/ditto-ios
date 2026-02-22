import Platform

public enum CoreModule {
  public static func platformMarker() -> PlatformModule.Type {
    PlatformModule.self
  }
}
