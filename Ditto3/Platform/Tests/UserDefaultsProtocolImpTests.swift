import Foundation
import Testing
@testable import Platform

struct UserDefaultsProtocolImpTests {
  @Test func typedAccessors() throws {
    let keyPrefix = "platform-tests-\(UUID().uuidString)"
    let userDefaults = try #require(UserDefaults(suiteName: keyPrefix))
    defer {
      userDefaults.removePersistentDomain(forName: keyPrefix)
    }

    userDefaults.set(value: 42, forKey: "int")
    userDefaults.set(value: "Jack", forKey: "string")
    userDefaults.set(value: [1, 2], forKey: "array")
    userDefaults.set(value: Set([1, 2, 3]), forKey: "set")

    #expect(userDefaults.integer(forKey: "int") == 42)
    #expect(userDefaults.string(forKey: "string") == "Jack")

    let array: [Int]? = userDefaults.array(forKey: "array")
    #expect(array == [1, 2])

    let set: Set<Int>? = userDefaults.set(forKey: "set")
    #expect(set == Set([1, 2, 3]))
  }
}
