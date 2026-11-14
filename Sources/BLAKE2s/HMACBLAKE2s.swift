// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// HMAC (RFC 2104) over unkeyed BLAKE2s-256 with a 64-byte block, as WireGuard
/// uses it.
public enum HMACBLAKE2s {
  /// The code for `message` under `key`. A key of any length is accepted, and one longer than
  /// the 64-byte block is replaced by its hash (RFC 2104, section 2).
  public static func authenticationCode(
    for message: RawSpan,
    key: RawSpan,
  ) -> BLAKE2Digest<32> {
    var keyBlock = InlineArray<64, UInt8>(repeating: 0)
    if key.byteCount > 64 {
      // A key longer than the block is replaced by its hash.
      var keyHasher = BLAKE2sCore(digestCount: 32)
      keyHasher.update(key)
      var hashedKey = BLAKE2Digest<32>(chain: keyHasher.finalize())
      for index in 0 ..< 32 {
        keyBlock[index] = hashedKey.span[index]
      }
      keyHasher.erase()
      zeroize(&hashedKey)
    } else {
      for index in 0 ..< key.byteCount {
        keyBlock[index] = key.unsafeLoad(fromByteOffset: index, as: UInt8.self)
      }
    }

    var pad = InlineArray<64, UInt8>(repeating: 0)
    for index in 0 ..< 64 {
      pad[index] = keyBlock[index] ^ 0x36
    }
    var inner = BLAKE2sCore(digestCount: 32)
    inner.update(pad.span.bytes)
    inner.update(message)
    var innerDigest = BLAKE2Digest<32>(chain: inner.finalize())

    for index in 0 ..< 64 {
      pad[index] = keyBlock[index] ^ 0x5C
    }
    var outer = BLAKE2sCore(digestCount: 32)
    outer.update(pad.span.bytes)
    outer.update(innerDigest.span.bytes)
    let code = BLAKE2Digest<32>(chain: outer.finalize())

    zeroize(&keyBlock)
    zeroize(&pad)
    zeroize(&innerDigest)
    inner.erase()
    outer.erase()
    return code
  }
}
