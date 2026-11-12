// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// A key read from bytes that are not 32 bytes long.
public enum X25519KeyError: Error, Equatable {
  case invalidLength
}

func checkKeyLength(_ bytes: RawSpan) throws(X25519KeyError) {
  guard bytes.byteCount == 32 else {
    throw .invalidLength
  }
}

func keyBytes(_ bytes: RawSpan) throws(X25519KeyError) -> InlineArray<32, UInt8> {
  try checkKeyLength(bytes)
  return InlineArray { bytes.unsafeLoad(fromByteOffset: $0, as: UInt8.self) }
}
