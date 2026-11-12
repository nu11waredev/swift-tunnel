// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// Little-endian reads and writes for the fixed message layouts.

extension RawSpan {
  /// Checks the type byte and the three zero bytes that open every message.
  /// The message is at least four bytes.
  func checkHeader(_ type: MessageType) throws(MessageError) {
    guard try MessageType(of: self) == type else {
      throw .wrongType
    }
    for offset in 1 ... 3 where unsafeLoad(fromByteOffset: offset, as: UInt8.self) != 0 {
      throw .nonzeroReserved
    }
  }

  /// The little-endian integer at `offset`.
  func loadLittleEndian<Integer: FixedWidthInteger>(
    fromByteOffset offset: Int,
    as _: Integer.Type,
  ) -> Integer {
    var value: Integer = 0
    for index in 0 ..< Integer.bitWidth / 8 {
      let byte = unsafeLoad(fromByteOffset: offset + index, as: UInt8.self)
      value |= Integer(byte) << (8 * index)
    }
    return value
  }

  /// The `count` bytes at `offset`.
  func loadBytes<let count: Int>(fromByteOffset offset: Int) -> InlineArray<count, UInt8> {
    InlineArray { index in
      unsafeLoad(fromByteOffset: offset + index, as: UInt8.self)
    }
  }
}

extension OutputSpan<UInt8> {
  mutating func appendLittleEndian(_ value: some FixedWidthInteger) {
    for index in 0 ..< type(of: value).bitWidth / 8 {
      append(UInt8(truncatingIfNeeded: value >> (8 * index)))
    }
  }

  mutating func append<let count: Int>(_ bytes: InlineArray<count, UInt8>) {
    for index in bytes.indices {
      append(bytes[index])
    }
  }
}
