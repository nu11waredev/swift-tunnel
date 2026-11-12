// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Testing
import X25519

struct RFC7748Tests {
  static let alice = X25519PrivateKey(
    bytes: InlineArray(hex: "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"),
  )
  static let bob = X25519PrivateKey(
    bytes: InlineArray(hex: "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb"),
  )
  static let shared = "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742"

  @Test func `section 6.1 Alice's public key`() {
    #expect(
      Self.alice.publicKey.span.hex
        == "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a",
    )
  }

  @Test func `section 6.1 Bob's public key`() {
    #expect(
      Self.bob.publicKey.span.hex
        == "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f",
    )
  }

  @Test func `section 6.1 Alice and Bob reach the same shared secret`() throws {
    let aliceSecret = try Self.alice.sharedSecret(with: Self.bob.publicKey)
    let bobSecret = try Self.bob.sharedSecret(with: Self.alice.publicKey)
    #expect(aliceSecret.span.hex == Self.shared)
    #expect(bobSecret.span.hex == Self.shared)
  }

  @Test(arguments: [
    (
      "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4",
      "e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c",
      "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552",
    ),
    (
      "4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d",
      "e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493",
      "95cbde9476e8907d7aade45cb4b873f88b595a68799fa152e6f8f7647aac7957",
    ),
  ])
  func `section 5.2 input and output pairs`(scalar: String, u: String, output: String) throws {
    let key = X25519PrivateKey(bytes: InlineArray(hex: scalar))
    let secret = try key.sharedSecret(with: X25519PublicKey(bytes: InlineArray(hex: u)))
    #expect(secret.span.hex == output)
  }

  @Test func `section 5.2 after one iteration`() throws {
    #expect(
      try iterate(1).hex == "422c8e7a6227d7bca1350b3e2bb7279f7897b87bb6854b783c60e80311ae3079",
    )
  }

  @Test func `section 5.2 after 1,000 iterations`() throws {
    #expect(
      try iterate(1000).hex == "684cf59ba83309552800ef566f2f4d3c1c3887c49360e3875f2eb94d99532c51",
    )
  }

  /// Runs when the environment variable `VEIL_LONG_TESTS` is set.
  @Test(.enabled(if: ProcessInfo.processInfo.environment["VEIL_LONG_TESTS"] != nil))
  func `section 5.2 after 1,000,000 iterations`() throws {
    #expect(
      try iterate(1_000_000).hex
        == "7c3911e0ab2586fd864497297e575e6f3bc601c0883c30df5f4dd2d24f665424",
    )
  }

  /// The iterated test of section 5.2: k and u start as 9, and each round sets
  /// k to X25519(k, u) and u to the old k.
  private func iterate(_ count: Int) throws -> [UInt8] {
    var k = InlineArray<32, UInt8>(hex: "09" + String(repeating: "00", count: 31))
    var u = k
    for _ in 0 ..< count {
      let output = try X25519PrivateKey(bytes: k).sharedSecret(with: X25519PublicKey(bytes: u))
      u = k
      k = InlineArray(output.span)
    }
    return k.indices.map { k[$0] }
  }
}
