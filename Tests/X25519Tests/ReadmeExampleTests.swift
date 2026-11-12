// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import X25519

/// The X25519 usage example in the README, verbatim, with both sides checked
/// to reach the same secret.
struct ReadmeExampleTests {
  @Test func `the README example compiles and both sides agree`() throws {
    // README begins
    let alice = X25519PrivateKey()
    let bob = X25519PrivateKey()

    // Each side sends the 32 bytes of its public key to the other.
    let fromAlice = try X25519PublicKey(alice.publicKey.span.bytes)
    let fromBob = try X25519PublicKey(bob.publicKey.span.bytes)

    let aliceSecret = try alice.sharedSecret(with: fromBob)
    let bobSecret = try bob.sharedSecret(with: fromAlice)
    // README ends

    #expect(aliceSecret.span.hex == bobSecret.span.hex)
    #expect(aliceSecret.span.count == 32)
  }
}
