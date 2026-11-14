// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// A keyed BLAKE2s hasher (RFC 7693, the keyed mode) producing `digestCount`
/// bytes, 1 to 32. It cannot be copied, and its state is wiped when it ends. The state is
/// not locked in memory, so it can still be swapped out to disk before then.
public struct KeyedBLAKE2s<let digestCount: Int>: ~Copyable {
  /// The state lives at one heap address for the hasher's whole life, so the
  /// zeroing in deinit reaches the only copy of the key block.
  private let state: UnsafeMutablePointer<BLAKE2sCore>

  /// Starts a keyed hash of no bytes. The key is 1 to 32 bytes, and any other length throws
  /// `BLAKE2KeyError.invalidLength`. It traps when `digestCount` is not from 1 to 32.
  public init(key: RawSpan) throws(BLAKE2KeyError) {
    precondition(1 ... 32 ~= digestCount, "A BLAKE2s digest is 1 to 32 bytes")
    guard 1 ... 32 ~= key.byteCount else {
      throw BLAKE2KeyError.invalidLength
    }
    state = .allocate(capacity: 1)
    state.initialize(to: BLAKE2sCore(digestCount: digestCount, keyCount: key.byteCount))
    state.pointee.absorbKey(key)
  }

  /// Adds `bytes` to the message. The digest is the same however a message is split
  /// across calls.
  public mutating func update(_ bytes: RawSpan) {
    state.pointee.update(bytes)
  }

  /// Ends the hash and returns the digest of every byte given to `update(_:)`. The key and
  /// the state are wiped before it returns.
  public consuming func finalize() -> BLAKE2Digest<digestCount> {
    BLAKE2Digest(chain: state.pointee.finalize())
  }

  deinit {
    state.pointee.erase()
    state.deallocate()
  }
}

/// A BLAKE2s key that is empty or longer than 32 bytes.
public enum BLAKE2KeyError: Error, Equatable {
  /// The key is empty or longer than 32 bytes.
  case invalidLength
}
