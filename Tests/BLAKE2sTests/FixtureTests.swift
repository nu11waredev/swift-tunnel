// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s
import Foundation
import Testing

/// Fixtures from Python's hashlib and hmac, written by `Fixtures/generate.py`.
struct FixtureTests {
  struct Fixtures: Decodable {
    let blake2s: [BLAKE2sFixture]
    let hmac: [HMACFixture]
    let counterBoundary: [CounterBoundaryFixture]
  }

  struct BLAKE2sFixture: Decodable, CustomTestStringConvertible {
    let digestCount: Int
    let key: String
    let input: String
    let output: String

    var testDescription: String {
      "\(digestCount)-byte digest, \(key.count / 2)-byte key, \(input.count / 2) bytes"
    }
  }

  struct HMACFixture: Decodable, CustomTestStringConvertible {
    let key: String
    let input: String
    let output: String

    var testDescription: String {
      "\(key.count / 2)-byte key, \(input.count / 2) bytes"
    }
  }

  struct CounterBoundaryFixture: Decodable, CustomTestStringConvertible {
    let start: UInt64
    let input: String
    let output: String

    var testDescription: String {
      "counter starts at \(String(start, radix: 16)), \(input.count / 2) bytes"
    }
  }

  static let file: Fixtures = {
    let url = Bundle.module.url(forResource: "blake2s-fixtures", withExtension: "json")!
    return try! JSONDecoder().decode(Fixtures.self, from: Data(contentsOf: url))
  }()

  @Test func `fixtures cover every digest length, keyed and unkeyed`() {
    let unkeyed = Set(fixtures(keyed: false).map(\.digestCount))
    let keyed = Set(fixtures(keyed: true).map(\.digestCount))
    #expect(unkeyed == Set(1 ... 32))
    #expect(keyed == Set(1 ... 32))
  }

  @Test(arguments: file.blake2s)
  func `BLAKE2s matches hashlib`(fixture: BLAKE2sFixture) throws {
    let hash = digestsByCount[fixture.digestCount - 1]
    let output = try hash([UInt8](hex: fixture.key), [UInt8](hex: fixture.input))
    #expect(output.hex == fixture.output)
  }

  @Test func `keyed fixtures use keys of 1, 16, 31 and 32 bytes for every digest length`() {
    for digestCount in 1 ... 32 {
      let keyCounts = Set(
        Self.file.blake2s
          .filter { $0.digestCount == digestCount && !$0.key.isEmpty }
          .map { $0.key.count / 2 },
      )
      #expect(keyCounts.isSuperset(of: [1, 16, 31, 32]), "digest length \(digestCount)")
    }
  }

  @Test func `HMAC fixtures have keys empty, shorter than, equal to and longer than a block`() {
    let keyCounts = Set(Self.file.hmac.map { $0.key.count / 2 })
    #expect(keyCounts.contains(0))
    #expect(keyCounts.contains { $0 < 64 })
    #expect(keyCounts.contains(64))
    #expect(keyCounts.contains { $0 > 64 })
  }

  @Test(arguments: file.hmac)
  func `HMAC-BLAKE2s matches Python's hmac`(fixture: HMACFixture) {
    let key = [UInt8](hex: fixture.key)
    let input = [UInt8](hex: fixture.input)
    let code = HMACBLAKE2s.authenticationCode(for: input.span.bytes, key: key.span.bytes)
    #expect(code.hex == fixture.output)
  }

  private func fixtures(keyed: Bool) -> [BLAKE2sFixture] {
    Self.file.blake2s.filter { $0.key.isEmpty != keyed }
  }
}

/// A hash of each digest length 1 to 32, keyed when the key is not empty.
private let digestsByCount: [@Sendable ([UInt8], [UInt8]) throws -> [UInt8]] = [
  digest(BLAKE2s<1>.self), digest(BLAKE2s<2>.self), digest(BLAKE2s<3>.self),
  digest(BLAKE2s<4>.self), digest(BLAKE2s<5>.self), digest(BLAKE2s<6>.self),
  digest(BLAKE2s<7>.self), digest(BLAKE2s<8>.self), digest(BLAKE2s<9>.self),
  digest(BLAKE2s<10>.self), digest(BLAKE2s<11>.self), digest(BLAKE2s<12>.self),
  digest(BLAKE2s<13>.self), digest(BLAKE2s<14>.self), digest(BLAKE2s<15>.self),
  digest(BLAKE2s<16>.self), digest(BLAKE2s<17>.self), digest(BLAKE2s<18>.self),
  digest(BLAKE2s<19>.self), digest(BLAKE2s<20>.self), digest(BLAKE2s<21>.self),
  digest(BLAKE2s<22>.self), digest(BLAKE2s<23>.self), digest(BLAKE2s<24>.self),
  digest(BLAKE2s<25>.self), digest(BLAKE2s<26>.self), digest(BLAKE2s<27>.self),
  digest(BLAKE2s<28>.self), digest(BLAKE2s<29>.self), digest(BLAKE2s<30>.self),
  digest(BLAKE2s<31>.self), digest(BLAKE2s<32>.self),
]

private func digest<let digestCount: Int>(
  _: BLAKE2s<digestCount>.Type,
) -> @Sendable ([UInt8], [UInt8]) throws -> [UInt8] {
  { key, input in
    if key.isEmpty {
      return BLAKE2s<digestCount>.hash(input.span.bytes).bytes
    }
    var hasher = try KeyedBLAKE2s<digestCount>(key: key.span.bytes)
    hasher.update(input.span.bytes)
    return hasher.finalize().bytes
  }
}
