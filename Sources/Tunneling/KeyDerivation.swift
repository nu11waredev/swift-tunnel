// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s

/// The key derivation function Kdf of the WireGuard paper, section 5.4: HKDF
/// (RFC 5869) over HMAC-BLAKE2s with an empty info string.
///
///     t0 = Hmac(key, input)
///     t1 = Hmac(t0, 0x01)
///     t2 = Hmac(t0, t1 || 0x02)
///     t3 = Hmac(t0, t2 || 0x03)
///
/// Each form returns the first `n` of `t1`, `t2` and `t3`. The caller wipes
/// the outputs with `zeroize(_:)` when it is done with them.
package enum KeyDerivation {
  package static func deriveOne(key: RawSpan, input: RawSpan) -> BLAKE2Digest<32> {
    var extracted = HMACBLAKE2s.authenticationCode(for: input, key: key)
    let first = expandFirst(from: extracted)
    zeroize(&extracted)
    return first
  }

  package static func deriveTwo(
    key: RawSpan,
    input: RawSpan,
  ) -> (BLAKE2Digest<32>, BLAKE2Digest<32>) {
    var extracted = HMACBLAKE2s.authenticationCode(for: input, key: key)
    let first = expandFirst(from: extracted)
    let second = expandNext(from: extracted, after: first, counter: 2)
    zeroize(&extracted)
    return (first, second)
  }

  package static func deriveThree(
    key: RawSpan,
    input: RawSpan,
  ) -> (BLAKE2Digest<32>, BLAKE2Digest<32>, BLAKE2Digest<32>) {
    var extracted = HMACBLAKE2s.authenticationCode(for: input, key: key)
    let first = expandFirst(from: extracted)
    let second = expandNext(from: extracted, after: first, counter: 2)
    let third = expandNext(from: extracted, after: second, counter: 3)
    zeroize(&extracted)
    return (first, second, third)
  }

  /// `t(counter)`, from the previous output and the counter byte.
  private static func expandNext(
    from extracted: BLAKE2Digest<32>,
    after previous: BLAKE2Digest<32>,
    counter: UInt8,
  ) -> BLAKE2Digest<32> {
    var message = InlineArray<33, UInt8>(repeating: counter)
    for index in 0 ..< 32 {
      message[index] = previous.span[index]
    }
    let output = HMACBLAKE2s.authenticationCode(for: message.span.bytes, key: extracted.span.bytes)
    zeroize(&message)
    return output
  }

  /// `t1`, with the counter byte 0x01 as the whole message.
  private static func expandFirst(from extracted: BLAKE2Digest<32>) -> BLAKE2Digest<32> {
    var message = InlineArray<1, UInt8>(repeating: 1)
    let output = HMACBLAKE2s.authenticationCode(for: message.span.bytes, key: extracted.span.bytes)
    zeroize(&message)
    return output
  }
}
