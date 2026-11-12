// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// The handshake initiation message of the WireGuard paper, section 5.4.2,
/// 148 bytes:
///
///     type 0x1 (1)  reserved 0 (3)  sender (4)  ephemeral (32)
///     static (32 + 16)  timestamp (12 + 16)  mac1 (16)  mac2 (16)
///
/// The encrypted fields hold the ciphertext and its 16-byte tag, the bytes as
/// they travel on the wire.
package struct HandshakeInitiation: BitwiseCopyable, Sendable {
  package static let byteCount = 148
  /// The bytes mac1 is computed over, every byte before it (section 5.4.4).
  package static let mac1CoveredBytes = 0 ..< 116
  /// The bytes mac2 is computed over, every byte before it, mac1 included.
  package static let mac2CoveredBytes = 0 ..< 132

  /// The initiator's index for the session, `I_i`.
  package var sender: UInt32
  package var ephemeral: InlineArray<32, UInt8>
  package var encryptedStatic: InlineArray<48, UInt8>
  package var encryptedTimestamp: InlineArray<28, UInt8>
  package var mac1: InlineArray<16, UInt8>
  package var mac2: InlineArray<16, UInt8>

  package init(
    sender: UInt32,
    ephemeral: InlineArray<32, UInt8>,
    encryptedStatic: InlineArray<48, UInt8>,
    encryptedTimestamp: InlineArray<28, UInt8>,
    mac1: InlineArray<16, UInt8>,
    mac2: InlineArray<16, UInt8>,
  ) {
    self.sender = sender
    self.ephemeral = ephemeral
    self.encryptedStatic = encryptedStatic
    self.encryptedTimestamp = encryptedTimestamp
    self.mac1 = mac1
    self.mac2 = mac2
  }

  package init(parsing message: RawSpan) throws(MessageError) {
    guard message.byteCount == Self.byteCount else {
      throw .wrongLength
    }
    try message.checkHeader(.handshakeInitiation)
    sender = message.loadLittleEndian(fromByteOffset: 4, as: UInt32.self)
    ephemeral = message.loadBytes(fromByteOffset: 8)
    encryptedStatic = message.loadBytes(fromByteOffset: 40)
    encryptedTimestamp = message.loadBytes(fromByteOffset: 88)
    mac1 = message.loadBytes(fromByteOffset: 116)
    mac2 = message.loadBytes(fromByteOffset: 132)
  }

  /// Appends the 148 bytes of the message. The output has room for them.
  package func serialize(into output: inout OutputSpan<UInt8>) {
    precondition(output.freeCapacity >= Self.byteCount, "The output has no room for the message")
    output.append(MessageType.handshakeInitiation.rawValue)
    output.append(repeating: 0, count: 3)
    output.appendLittleEndian(sender)
    output.append(ephemeral)
    output.append(encryptedStatic)
    output.append(encryptedTimestamp)
    output.append(mac1)
    output.append(mac2)
  }
}
