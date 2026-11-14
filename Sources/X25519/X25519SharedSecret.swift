// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// The 32-byte secret two X25519 keys agree. It cannot be copied, and its
/// bytes are zeroized when it ends. `X25519PrivateKey.sharedSecret(with:)`
/// returns it.
public struct X25519SharedSecret: ~Copyable, @unchecked Sendable {
  /// The bytes live at one heap address for the secret's whole life, so the
  /// zeroing in deinit reaches the only stored copy. Between init and deinit they are
  /// only read, which is what lets the secret be shared across concurrency
  /// domains.
  private let storage: UnsafeMutablePointer<InlineArray<32, UInt8>>

  init(bytes: InlineArray<32, UInt8>) {
    storage = .allocate(capacity: 1)
    storage.initialize(to: bytes)
  }

  deinit {
    zeroize(&storage.pointee)
    storage.deallocate()
  }

  /// The 32 bytes of the secret.
  public var span: Span<UInt8> {
    @_lifetime(borrow self)
    borrowing get {
      // The 32 bytes stay at this address until deinit, which cannot run
      // while self is borrowed.
      let elements = UnsafeBufferPointer(
        start: UnsafeRawPointer(storage).assumingMemoryBound(to: UInt8.self),
        count: 32,
      )
      return _overrideLifetime(Span(_unsafeElements: elements), borrowing: self)
    }
  }
}

/// A shared secret that came out all zero, because the peer's public key is a
/// point of small order (RFC 7748, section 6.1).
public enum X25519SharedSecretError: Error, Equatable {
  /// The result was all zero.
  case allZero
}
