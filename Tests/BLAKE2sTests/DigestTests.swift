// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s
import Testing

struct DigestTests {
  @Test func `digests of the same input are equal`() {
    let message = Array("abc".utf8)
    #expect(BLAKE2s<32>.hash(message.span.bytes) == BLAKE2s<32>.hash(message.span.bytes))
  }

  @Test func `digests of different inputs are not equal`() {
    let first = Array("abc".utf8)
    let second = Array("abd".utf8)
    #expect(BLAKE2s<32>.hash(first.span.bytes) != BLAKE2s<32>.hash(second.span.bytes))
  }
}
