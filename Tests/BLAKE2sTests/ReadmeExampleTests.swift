// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s
import Testing

/// The usage example in the README, verbatim, with its results checked against
/// Python's hashlib and hmac.
struct ReadmeExampleTests {
  @Test func `the README example compiles and gives the documented digests`() throws {
    // README begins
    let message = Array("hello".utf8)
    let key = Array("0123456789abcdef0123456789abcdef".utf8)

    let digest = BLAKE2s<32>.hash(message.span.bytes)

    var hasher = try KeyedBLAKE2s<32>(key: key.span.bytes)
    hasher.update(message.span.bytes)
    let tag = hasher.finalize()

    let code = HMACBLAKE2s.authenticationCode(for: message.span.bytes, key: key.span.bytes)
    // README ends

    #expect(digest.hex == "19213bacc58dee6dbde3ceb9a47cbb330b3d86f8cca8997eb00be456f140ca25")
    #expect(tag.hex == "6dfc6fbdfac33b71832c8020c122f3ec974330b677b90101d6452284e3f0e14c")
    #expect(code.hex == "0afe9cbf3578e981aef7e0aabc7d2589ef05c03c83b9bd9a14a49860a45d7f68")
  }
}
