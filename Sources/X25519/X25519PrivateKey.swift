// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// An X25519 private key: 32 bytes, clamped as RFC 7748, section 5,
/// describes each time the key is used. It cannot be copied, and its bytes are
/// zeroized when it ends.
public struct X25519PrivateKey: ~Copyable, @unchecked Sendable {
  /// The bytes live at one heap address for the key's whole life, so the
  /// zeroing in deinit reaches the only copy. Between init and deinit they are
  /// only read, which is what lets the key be shared across concurrency
  /// domains.
  private let storage: UnsafeMutablePointer<InlineArray<32, UInt8>>

  /// A new key of 32 bytes from `SystemRandomNumberGenerator`.
  public init() {
    storage = .allocate(capacity: 1)
    storage.initialize(to: InlineArray(repeating: 0))
    var generator = SystemRandomNumberGenerator()
    for word in 0 ..< 4 {
      var random = generator.next()
      for byte in 0 ..< 8 {
        storage.pointee[8 * word + byte] = UInt8(truncatingIfNeeded: random >> (8 * byte))
      }
      zeroize(&random)
    }
  }

  public init(bytes: InlineArray<32, UInt8>) {
    storage = .allocate(capacity: 1)
    storage.initialize(to: bytes)
  }

  /// A key from 32 bytes. Any other length throws `X25519KeyError.invalidLength`.
  public init(_ bytes: RawSpan) throws(X25519KeyError) {
    try checkKeyLength(bytes)
    storage = .allocate(capacity: 1)
    storage.initialize(to: InlineArray(repeating: 0))
    for index in 0 ..< 32 {
      storage.pointee[index] = bytes.unsafeLoad(fromByteOffset: index, as: UInt8.self)
    }
  }

  deinit {
    zeroize(&storage.pointee)
    storage.deallocate()
  }

  /// The 32 bytes as given, before clamping.
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

  /// The public key, the scalar times the base point 9.
  public var publicKey: X25519PublicKey {
    borrowing get {
      X25519PublicKey(bytes: x25519(scalar: storage.pointee, u: basePoint))
    }
  }

  /// The secret shared with the holder of `peer`'s private key (RFC 7748,
  /// section 6.1). It throws `X25519SharedSecretError.allZero` when `peer`
  /// is a point of small order.
  public borrowing func sharedSecret(
    with peer: X25519PublicKey,
  ) throws(X25519SharedSecretError) -> X25519SharedSecret {
    var output = x25519(scalar: storage.pointee, u: peer.bytes)
    defer { zeroize(&output) }
    guard !isAllZero(output) else {
      throw .allZero
    }
    return X25519SharedSecret(bytes: output)
  }
}
