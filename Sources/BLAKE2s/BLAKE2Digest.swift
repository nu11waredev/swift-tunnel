// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// A BLAKE2 digest of `count` bytes.
public struct BLAKE2Digest<let count: Int>: BitwiseCopyable, Sendable {
  private let storage: InlineArray<count, UInt8>

  /// Serializes the first `count` bytes of the chain value, little-endian.
  init(chain: InlineArray<8, UInt32>) {
    storage = InlineArray { index in
      UInt8(truncatingIfNeeded: chain[index / 4] >> (8 * (index % 4)))
    }
  }

  public var span: Span<UInt8> {
    @_lifetime(borrow self)
    get {
      storage.span
    }
  }
}

extension BLAKE2Digest: Equatable {
  /// Compares every byte whatever the input, so the time taken says nothing
  /// about where two digests differ.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    var difference: UInt8 = 0
    for index in 0 ..< count {
      difference |= lhs.storage[index] ^ rhs.storage[index]
    }
    return difference == 0
  }
}
