import DittoIO
import Foundation

public final class UserDefaultsMock: UserDefaultsProtocol {
  private var dictionary: [String: Any] = [:]

  public func register(defaults registrationDictionary: [String: Any]) {
    self.dictionary = registrationDictionary
  }

  public func bool(forKey defaultName: String) -> Bool {
    return self.dictionary[defaultName] as! Bool
  }

  public func integer(forKey defaultName: String) -> Int {
    return self.dictionary[defaultName] as! Int
  }

  public func double(forKey defaultName: String) -> Double {
    return self.dictionary[defaultName] as! Double
  }

  public func string(forKey defaultName: String) -> String? {
    return self.dictionary[defaultName] as? String
  }

  public func data(forKey defaultName: String) -> Data? {
    return self.dictionary[defaultName] as? Data
  }

  public func value(forKey defaultName: String) -> Any? {
    return self.dictionary[defaultName]
  }

  public func setValue(_ value: Any?, forKey defaultName: String) {
    self.dictionary[defaultName] = value
  }
}
