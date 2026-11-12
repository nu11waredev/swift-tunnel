// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// An unkeyed BLAKE2s hasher (RFC 7693) producing `digestCount` bytes, 1 to 32. It does not
/// wipe its state, so secrets belong in `KeyedBLAKE2s`.
public struct BLAKE2s<let digestCount: Int>: Sendable {
  private var core: BLAKE2sCore

  public init() {
    precondition(1 ... 32 ~= digestCount, "A BLAKE2s digest is 1 to 32 bytes")
    core = BLAKE2sCore(digestCount: digestCount)
  }

  public mutating func update(_ bytes: RawSpan) {
    core.update(bytes)
  }

  public consuming func finalize() -> BLAKE2Digest<digestCount> {
    BLAKE2Digest(chain: core.finalize())
  }

  public static func hash(_ bytes: RawSpan) -> BLAKE2Digest<digestCount> {
    var hasher = Self()
    hasher.update(bytes)
    return hasher.finalize()
  }
}
