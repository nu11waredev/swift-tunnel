// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import X25519

struct KeyTests {
  static let alice = X25519PrivateKey(
    bytes: InlineArray(hex: "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"),
  )
  static let bob = X25519PublicKey(
    bytes: InlineArray(hex: "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"),
  )

  @Test(arguments: [0, 31, 33, 64])
  func `a private key of another length than 32 bytes throws`(count: Int) {
    let bytes = [UInt8](repeating: 1, count: count)
    #expect(throws: X25519KeyError.invalidLength) {
      _ = try X25519PrivateKey(bytes.span.bytes)
    }
  }

  @Test(arguments: [0, 31, 33, 64])
  func `a public key of another length than 32 bytes throws`(count: Int) {
    let bytes = [UInt8](repeating: 1, count: count)
    #expect(throws: X25519KeyError.invalidLength) {
      try X25519PublicKey(bytes.span.bytes)
    }
  }

  @Test func `keys read from bytes give the section 6.1 shared secret`() throws {
    let aliceBytes =
      [UInt8](hex: "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a")
    let bobBytes = [UInt8](hex: "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f")
    let alice = try X25519PrivateKey(aliceBytes.span.bytes)
    let bob = try X25519PublicKey(bobBytes.span.bytes)
    let secret = try alice.sharedSecret(with: bob)
    #expect(secret.span.hex == "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742")
    #expect(alice.span.hex == aliceBytes.hex)
    #expect(bob.span.hex == bobBytes.hex)
  }

  @Test func `public keys compare by their bytes`() {
    #expect(Self.alice.publicKey == X25519PublicKey(bytes: InlineArray(
      hex: "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a",
    )))
    #expect(Self.alice.publicKey != Self.bob)
  }

  @Test func `two generated keys differ and agree a shared secret`() throws {
    let first = X25519PrivateKey()
    let second = X25519PrivateKey()
    #expect(first.span.hex != second.span.hex)
    #expect(first.publicKey != second.publicKey)
    let one = try first.sharedSecret(with: second.publicKey)
    let other = try second.sharedSecret(with: first.publicKey)
    #expect(one.span.hex == other.span.hex)
  }

  @Test func `one private key agrees secrets with several peers`() throws {
    let carol = X25519PrivateKey()
    let withBob = try Self.alice.sharedSecret(with: Self.bob)
    let withCarol = try Self.alice.sharedSecret(with: carol.publicKey)
    let fromCarol = try carol.sharedSecret(with: Self.alice.publicKey)
    #expect(withBob.span.hex == "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742")
    #expect(withCarol.span.hex == fromCarol.span.hex)
    #expect(withCarol.span.hex != withBob.span.hex)
  }

  @Test func `a private key gives the same results from concurrent tasks`() async throws {
    let results = try await withThrowingTaskGroup(of: String.self) { group in
      for _ in 0 ..< 8 {
        group.addTask {
          let secret = try Self.alice.sharedSecret(with: Self.bob)
          return secret.span.hex
        }
      }
      return try await group.reduce(into: Set<String>()) { $0.insert($1) }
    }
    #expect(results == ["4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742"])
  }

  @Test func `a shared secret keeps its bytes when it moves`() throws {
    struct Session: ~Copyable {
      let secret: X25519SharedSecret
    }
    let session = try Session(secret: Self.alice.sharedSecret(with: Self.bob))
    let moved = consume session
    #expect(
      moved.secret.span.hex == "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742",
    )
  }
}
