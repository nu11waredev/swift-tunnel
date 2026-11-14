// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Testing
import X25519

/// Fixtures written by `Fixtures/generate.py` from the formulas of RFC 7748,
/// and the points of small order listed at cr.yp.to/ecdh.html.
struct FixtureTests {
  struct Fixtures: Decodable {
    let lowOrder: [String]
    let nonCanonical: [ExchangeFixture]
    let topBit: [ExchangeFixture]
    let exchange: [ExchangeFixture]
  }

  struct ExchangeFixture: Decodable, CustomTestStringConvertible {
    let scalar: String
    let u: String
    let output: String

    var testDescription: String {
      "u = \(u)"
    }
  }

  static let file: Fixtures = {
    let url = Bundle.module.url(forResource: "x25519-fixtures", withExtension: "json")!
    return try! JSONDecoder().decode(Fixtures.self, from: Data(contentsOf: url))
  }()

  static let scalar = X25519PrivateKey(
    bytes: InlineArray(hex: "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4"),
  )

  @Test(arguments: file.lowOrder)
  func `a point of small order gives the all-zero error`(u: String) {
    let peer = X25519PublicKey(bytes: InlineArray(hex: u))
    #expect(throws: X25519SharedSecretError.allZero) {
      _ = try Self.scalar.sharedSecret(with: peer)
    }
  }

  @Test func `the non-canonical fixtures cover 2^255 - 17 to 2^255 - 1`() {
    let lowBytes = Self.file.nonCanonical.map { [UInt8](hex: $0.u)[0] }
    #expect(lowBytes == Array(0xEF ... 0xFF))
  }

  @Test(arguments: file.nonCanonical)
  func `a non-canonical u-coordinate counts as the value reduced modulo p`(
    fixture: ExchangeFixture,
  ) throws {
    try expectOutput(fixture)
  }

  @Test(arguments: file.nonCanonical)
  func `a non-canonical u-coordinate matches its reduced form`(fixture: ExchangeFixture) throws {
    // u - p is the first byte of u minus 0xED, below 19, in the lowest byte.
    var reduced = [UInt8](repeating: 0, count: 32)
    reduced[0] = [UInt8](hex: fixture.u)[0] - 0xED
    let key = X25519PrivateKey(bytes: InlineArray(hex: fixture.scalar))
    let fromReduced = try key
      .sharedSecret(with: X25519PublicKey(bytes: InlineArray(hex: reduced.hex)))
    let fromNonCanonical = try key.sharedSecret(
      with: X25519PublicKey(bytes: InlineArray(hex: fixture.u)),
    )
    #expect(fromNonCanonical.span.hex == fromReduced.span.hex)
  }

  @Test(arguments: file.topBit)
  func `bit 255 of the u-coordinate is masked`(fixture: ExchangeFixture) throws {
    try expectOutput(fixture)
  }

  @Test(arguments: file.topBit)
  func `a u-coordinate with bit 255 set matches it cleared`(fixture: ExchangeFixture) throws {
    var cleared = [UInt8](hex: fixture.u)
    cleared[31] &= 0x7F
    let key = X25519PrivateKey(bytes: InlineArray(hex: fixture.scalar))
    let fromCleared = try key
      .sharedSecret(with: X25519PublicKey(bytes: InlineArray(hex: cleared.hex)))
    let fromSet = try key.sharedSecret(with: X25519PublicKey(bytes: InlineArray(hex: fixture.u)))
    #expect(fromSet.span.hex == fromCleared.span.hex)
  }

  @Test(arguments: file.exchange)
  func `X25519 matches the RFC 7748 formulas`(fixture: ExchangeFixture) throws {
    try expectOutput(fixture)
  }

  private func expectOutput(_ fixture: ExchangeFixture) throws {
    let key = X25519PrivateKey(bytes: InlineArray(hex: fixture.scalar))
    let secret = try key.sharedSecret(with: X25519PublicKey(bytes: InlineArray(hex: fixture.u)))
    #expect(secret.span.hex == fixture.output)
  }
}
