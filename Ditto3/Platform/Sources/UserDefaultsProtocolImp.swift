import Foundation

extension UserDefaults: UserDefaultsProtocol {
  public func array<T>(forKey key: String) -> [T]? {
    array(forKey: key) as? [T]
  }

  public func set<T: Hashable>(forKey key: String) -> Set<T>? {
    guard let array = array(forKey: key) as? [T] else { return nil }
    return Set(array)
  }

  public func set(value: Int, forKey key: String) {
    set(value, forKey: key)
  }

  public func set(value: String?, forKey key: String) {
    set(value, forKey: key)
  }

  public func set<T>(value: [T]?, forKey key: String) {
    set(value, forKey: key)
  }

  public func set<T: Hashable>(value: Set<T>?, forKey defaultName: String) {
    guard let value else {
      set(nil, forKey: defaultName)
      return
    }
    set(Array(value), forKey: defaultName)
  }
}
