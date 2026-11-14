// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// An X25519 public key: a u-coordinate of 32 bytes, little-endian. Every
/// 32-byte string is accepted. Bit 255 is ignored, and a value from p to
/// 2^255 - 1 counts as the value reduced modulo p (RFC 7748, section 5).
public struct X25519PublicKey: BitwiseCopyable, Sendable {
  private let storage: InlineArray<32, UInt8>

  /// A key from 32 bytes, kept as given.
  public init(bytes: InlineArray<32, UInt8>) {
    storage = bytes
  }

  /// A key from 32 bytes. Any other length throws `X25519KeyError.invalidLength`.
  public init(_ bytes: RawSpan) throws(X25519KeyError) {
    storage = try keyBytes(bytes)
  }

  var bytes: InlineArray<32, UInt8> {
    storage
  }

  /// The 32 bytes as given.
  public var span: Span<UInt8> {
    @_lifetime(borrow self)
    get {
      storage.span
    }
  }
}

extension X25519PublicKey: Hashable {
  /// Compares the 32 bytes as given, so two encodings of one u-coordinate
  /// compare as different keys.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    for index in 0 ..< 32 where lhs.storage[index] != rhs.storage[index] {
      return false
    }
    return true
  }

  /// Hashes the 32 bytes as given, which agrees with `==`.
  public func hash(into hasher: inout Hasher) {
    for index in 0 ..< 32 {
      hasher.combine(storage[index])
    }
  }
}
