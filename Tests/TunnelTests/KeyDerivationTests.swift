// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s
import Foundation
import Testing
import Tunnel

/// Key derivation against Python's hmac, with the fixtures written by
/// `Fixtures/generate.py`.
struct KeyDerivationTests {
  struct Fixtures: Decodable {
    let kdf: [KDFFixture]
  }

  struct KDFFixture: Decodable, CustomTestStringConvertible {
    let key: String
    let input: String
    let output1: String
    let output2: String
    let output3: String

    var testDescription: String {
      "\(key.count / 2)-byte key, \(input.count / 2)-byte input"
    }
  }

  static let file: Fixtures = {
    let url = Bundle.module.url(forResource: "kdf-fixtures", withExtension: "json")!
    return try! JSONDecoder().decode(Fixtures.self, from: Data(contentsOf: url))
  }()

  @Test(arguments: file.kdf)
  func `one output matches Python's hmac`(fixture: KDFFixture) {
    let key = [UInt8](hex: fixture.key)
    let input = [UInt8](hex: fixture.input)
    let output = KeyDerivation.deriveOne(key: key.span.bytes, input: input.span.bytes)
    #expect(output.hex == fixture.output1)
  }

  @Test(arguments: file.kdf)
  func `two outputs match Python's hmac`(fixture: KDFFixture) {
    let key = [UInt8](hex: fixture.key)
    let input = [UInt8](hex: fixture.input)
    let (first, second) = KeyDerivation.deriveTwo(key: key.span.bytes, input: input.span.bytes)
    #expect(first.hex == fixture.output1)
    #expect(second.hex == fixture.output2)
  }

  @Test(arguments: file.kdf)
  func `three outputs match Python's hmac`(fixture: KDFFixture) {
    let key = [UInt8](hex: fixture.key)
    let input = [UInt8](hex: fixture.input)
    let (first, second, third) = KeyDerivation.deriveThree(
      key: key.span.bytes,
      input: input.span.bytes,
    )
    #expect(first.hex == fixture.output1)
    #expect(second.hex == fixture.output2)
    #expect(third.hex == fixture.output3)
  }

  @Test func `fixtures have keys empty, shorter than, equal to and longer than a block`() {
    let keyCounts = Set(Self.file.kdf.map { $0.key.count / 2 })
    #expect(keyCounts.contains(0))
    #expect(keyCounts.contains { $0 < 64 })
    #expect(keyCounts.contains(64))
    #expect(keyCounts.contains { $0 > 64 })
  }

  @Test func `fixtures include an empty input`() {
    #expect(Self.file.kdf.contains { $0.input.isEmpty })
  }

  @Test(arguments: file.kdf)
  func `each form gives the leading outputs of the longer forms`(fixture: KDFFixture) {
    let key = [UInt8](hex: fixture.key)
    let input = [UInt8](hex: fixture.input)
    let one = KeyDerivation.deriveOne(key: key.span.bytes, input: input.span.bytes)
    let two = KeyDerivation.deriveTwo(key: key.span.bytes, input: input.span.bytes)
    let three = KeyDerivation.deriveThree(key: key.span.bytes, input: input.span.bytes)
    #expect(one == two.0)
    #expect(two.0 == three.0)
    #expect(two.1 == three.1)
  }

  @Test(arguments: file.kdf)
  func `the three outputs differ from one another`(fixture: KDFFixture) {
    let key = [UInt8](hex: fixture.key)
    let input = [UInt8](hex: fixture.input)
    let (first, second, third) = KeyDerivation.deriveThree(
      key: key.span.bytes,
      input: input.span.bytes,
    )
    #expect(first != second)
    #expect(second != third)
    #expect(first != third)
  }

  @Test func `deriving again with the same key and input gives the same outputs`() {
    let key = [UInt8](repeating: 0x42, count: 32)
    let input = [UInt8](repeating: 0x17, count: 5)
    let first = KeyDerivation.deriveThree(key: key.span.bytes, input: input.span.bytes)
    let second = KeyDerivation.deriveThree(key: key.span.bytes, input: input.span.bytes)
    #expect(first.0 == second.0)
    #expect(first.1 == second.1)
    #expect(first.2 == second.2)
  }

  @Test func `a changed key or input changes the output`() {
    let key = [UInt8](repeating: 0x42, count: 32)
    var otherKey = key
    otherKey[31] ^= 1
    let input = [UInt8](repeating: 0x17, count: 5)
    var otherInput = input
    otherInput[4] ^= 1
    let output = KeyDerivation.deriveOne(key: key.span.bytes, input: input.span.bytes)
    #expect(output != KeyDerivation.deriveOne(key: otherKey.span.bytes, input: input.span.bytes))
    #expect(output != KeyDerivation.deriveOne(key: key.span.bytes, input: otherInput.span.bytes))
  }

  @Test func `zeroize clears the one returned output`() {
    let key = [UInt8](repeating: 0x42, count: 32)
    let input = [UInt8](repeating: 0x17, count: 5)
    var output = KeyDerivation.deriveOne(key: key.span.bytes, input: input.span.bytes)
    #expect(output.bytes != zeros)
    zeroize(&output)
    #expect(output.bytes == zeros)
  }

  @Test func `zeroize clears both returned outputs`() {
    let key = [UInt8](repeating: 0x42, count: 32)
    let input = [UInt8](repeating: 0x17, count: 5)
    var outputs = KeyDerivation.deriveTwo(key: key.span.bytes, input: input.span.bytes)
    #expect(outputs.0.bytes != zeros)
    #expect(outputs.1.bytes != zeros)
    zeroize(&outputs)
    #expect(outputs.0.bytes == zeros)
    #expect(outputs.1.bytes == zeros)
  }

  @Test func `zeroize clears all three returned outputs`() {
    let key = [UInt8](repeating: 0x42, count: 32)
    let input = [UInt8](repeating: 0x17, count: 5)
    var outputs = KeyDerivation.deriveThree(key: key.span.bytes, input: input.span.bytes)
    #expect(outputs.0.bytes != zeros)
    #expect(outputs.1.bytes != zeros)
    #expect(outputs.2.bytes != zeros)
    zeroize(&outputs)
    #expect(outputs.0.bytes == zeros)
    #expect(outputs.1.bytes == zeros)
    #expect(outputs.2.bytes == zeros)
  }

  private let zeros = [UInt8](repeating: 0, count: 32)
}
