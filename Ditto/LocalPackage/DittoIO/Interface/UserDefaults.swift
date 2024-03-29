import Foundation

public protocol UserDefaultsProtocol {
  func register(defaults registrationDictionary: [String: Any])
  func bool(forKey defaultName: String) -> Bool
  func integer(forKey defaultName: String) -> Int
  func double(forKey defaultName: String) -> Double
  func string(forKey defaultName: String) -> String?
  func data(forKey defaultName: String) -> Data?
  func value(forKey defaultName: String) -> Any?
  func setValue(_ value: Any?, forKey defaultName: String)
}
