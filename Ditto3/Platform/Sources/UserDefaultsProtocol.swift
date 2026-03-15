import Foundation

public protocol UserDefaultsProtocol: Sendable {
  func integer(forKey key: String) -> Int
  func string(forKey key: String) -> String?
  func array<T>(forKey key: String) -> [T]?
  func set<T: Hashable>(forKey key: String) -> Set<T>?

  func set(value: Int, forKey key: String)
  func set(value: String?, forKey key: String)
  func set<T>(value: [T]?, forKey key: String)
  func set<T: Hashable>(value: Set<T>?, forKey defaultName: String)
}
