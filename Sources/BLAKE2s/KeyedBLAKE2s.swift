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

  /// Starts a keyed hash. The key is 1 to 32 bytes.
  public init(key: RawSpan) throws(BLAKE2KeyError) {
    precondition(1 ... 32 ~= digestCount, "A BLAKE2s digest is 1 to 32 bytes")
    guard 1 ... 32 ~= key.byteCount else {
      throw BLAKE2KeyError.invalidLength
    }
    state = .allocate(capacity: 1)
    state.initialize(to: BLAKE2sCore(digestCount: digestCount, keyCount: key.byteCount))
    state.pointee.absorbKey(key)
  }

  public mutating func update(_ bytes: RawSpan) {
    state.pointee.update(bytes)
  }

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
  case invalidLength
}
