import Foundation
import Platform

public final class UserDefaultsMock: UserDefaultsProtocol, @unchecked Sendable {
  private var storage: [String: Any] = [:]
  private var setReadCounts: [String: Int] = [:]

  public init() {}

  public func stubSet<T: Hashable>(_ value: Set<T>?, forKey key: String) {
    storage[key] = value
  }

  public func setReadCount(forKey key: String) -> Int {
    setReadCounts[key, default: 0]
  }

  public func persistedSet<T: Hashable>(forKey key: String) -> Set<T>? {
    storage[key] as? Set<T>
  }

  public func integer(forKey key: String) -> Int {
    storage[key] as? Int ?? 0
  }

  public func string(forKey key: String) -> String? {
    storage[key] as? String
  }

  public func array<T>(forKey key: String) -> [T]? {
    storage[key] as? [T]
  }

  public func set<T: Hashable>(forKey key: String) -> Set<T>? {
    setReadCounts[key, default: 0] += 1
    return storage[key] as? Set<T>
  }

  public func set(value: Int, forKey key: String) {
    storage[key] = value
  }

  public func set(value: String?, forKey key: String) {
    storage[key] = value
  }

  public func set<T>(value: [T]?, forKey key: String) {
    storage[key] = value
  }

  public func set<T: Hashable>(value: Set<T>?, forKey key: String) {
    storage[key] = value
  }
}
