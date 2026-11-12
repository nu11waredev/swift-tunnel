// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#elseif canImport(Musl)
  import Musl
#endif

/// The BLAKE2s state of RFC 7693, section 3, shared by every hasher in the module.
struct BLAKE2sCore {
  private var chain: InlineArray<8, UInt32>
  private var block: InlineArray<64, UInt8>
  private var blockFill: Int
  /// The bytes in the blocks compressed so far. Tests start it near 2^32 to reach the carry
  /// from t0 into t1.
  var byteCount: UInt64

  /// A keyed hash also needs `absorbKey(_:)` with a key of `keyCount` bytes.
  init(digestCount: Int, keyCount: Int = 0) {
    chain = initializationVector
    // Parameter block word 0: digest length, key length, fanout 1, depth 1.
    chain[0] ^= 0x0101_0000 ^ UInt32(keyCount) << 8 ^ UInt32(digestCount)
    block = InlineArray(repeating: 0)
    blockFill = 0
    byteCount = 0
  }

  /// Makes the key, zero-padded to a full block, the first block. Called once,
  /// before any input.
  mutating func absorbKey(_ key: RawSpan) {
    update(key)
    blockFill = 64
  }

  mutating func update(_ bytes: RawSpan) {
    for offset in 0 ..< bytes.byteCount {
      // A full block is compressed only once more input arrives, because the
      // final block must be compressed with the finalization flag set.
      if blockFill == 64 {
        byteCount &+= 64
        compress(isFinal: false)
        blockFill = 0
      }
      block[blockFill] = bytes.unsafeLoad(fromByteOffset: offset, as: UInt8.self)
      blockFill += 1
    }
  }

  mutating func finalize() -> InlineArray<8, UInt32> {
    byteCount &+= UInt64(blockFill)
    for index in blockFill ..< 64 {
      block[index] = 0
    }
    compress(isFinal: true)
    return chain
  }

  mutating func erase() {
    zeroize(&self)
  }

  private mutating func compress(isFinal: Bool) {
    var message = InlineArray<16, UInt32>(repeating: 0)
    for index in 0 ..< 16 {
      message[index] =
        UInt32(block[4 * index])
          | UInt32(block[4 * index + 1]) << 8
          | UInt32(block[4 * index + 2]) << 16
          | UInt32(block[4 * index + 3]) << 24
    }

    var work = InlineArray<16, UInt32>(repeating: 0)
    for index in 0 ..< 8 {
      work[index] = chain[index]
      work[index + 8] = initializationVector[index]
    }
    work[12] ^= UInt32(truncatingIfNeeded: byteCount)
    work[13] ^= UInt32(truncatingIfNeeded: byteCount >> 32)
    if isFinal {
      work[14] = ~work[14]
    }

    for round in 0 ..< 10 {
      let schedule = round * 16
      func word(_ position: Int) -> UInt32 {
        message[messageSchedule[schedule + position]]
      }
      mix(&work, 0, 4, 8, 12, word(0), word(1))
      mix(&work, 1, 5, 9, 13, word(2), word(3))
      mix(&work, 2, 6, 10, 14, word(4), word(5))
      mix(&work, 3, 7, 11, 15, word(6), word(7))
      mix(&work, 0, 5, 10, 15, word(8), word(9))
      mix(&work, 1, 6, 11, 12, word(10), word(11))
      mix(&work, 2, 7, 8, 13, word(12), word(13))
      mix(&work, 3, 4, 9, 14, word(14), word(15))
    }

    for index in 0 ..< 8 {
      chain[index] ^= work[index] ^ work[index + 8]
    }

    zeroize(&message)
    zeroize(&work)
  }
}

/// Overwrites a value's bytes with zeros in a way the optimizer keeps.
package func zeroize(_ value: inout some BitwiseCopyable) {
  withUnsafeMutableBytes(of: &value) { bytes in
    // An empty value has no address and nothing to wipe.
    guard let base = bytes.baseAddress else { return }
    #if canImport(Darwin)
      _ = memset_s(base, bytes.count, 0, bytes.count)
    #else
      explicit_bzero(base, bytes.count)
    #endif
  }
}

/// The mixing function G of RFC 7693, section 3.1, with the BLAKE2s rotations.
private func mix(
  _ work: inout InlineArray<16, UInt32>,
  _ a: Int,
  _ b: Int,
  _ c: Int,
  _ d: Int,
  _ x: UInt32,
  _ y: UInt32,
) {
  work[a] = work[a] &+ work[b] &+ x
  work[d] = rotateRight(work[d] ^ work[a], by: 16)
  work[c] = work[c] &+ work[d]
  work[b] = rotateRight(work[b] ^ work[c], by: 12)
  work[a] = work[a] &+ work[b] &+ y
  work[d] = rotateRight(work[d] ^ work[a], by: 8)
  work[c] = work[c] &+ work[d]
  work[b] = rotateRight(work[b] ^ work[c], by: 7)
}

private func rotateRight(_ value: UInt32, by count: UInt32) -> UInt32 {
  value >> count | value << (32 - count)
}

private let initializationVector: InlineArray<8, UInt32> = [
  0x6A09_E667, 0xBB67_AE85, 0x3C6E_F372, 0xA54F_F53A,
  0x510E_527F, 0x9B05_688C, 0x1F83_D9AB, 0x5BE0_CD19,
]

/// SIGMA of RFC 7693, section 2.7: the message word order for each of the ten rounds.
private let messageSchedule: InlineArray<160, Int> = [
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
  14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3,
  11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4,
  7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8,
  9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13,
  2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9,
  12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11,
  13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10,
  6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5,
  10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0,
]
