// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// The handshake response message of the WireGuard paper, section 5.4.3,
/// 92 bytes:
///
///     type 0x2 (1)  reserved 0 (3)  sender (4)  receiver (4)
///     ephemeral (32)  empty (0 + 16)  mac1 (16)  mac2 (16)
///
/// The encrypted field is the 16-byte tag over an empty plaintext, the bytes as
/// they travel on the wire.
package struct HandshakeResponse: BitwiseCopyable, Sendable {
  package static let byteCount = 92
  /// The bytes mac1 is computed over, every byte before it (section 5.4.4).
  package static let mac1CoveredBytes = 0 ..< 60
  /// The bytes mac2 is computed over, every byte before it, mac1 included.
  package static let mac2CoveredBytes = 0 ..< 76

  /// The responder's index for the session, `I_r`.
  package var sender: UInt32
  /// The initiator's index from the initiation, `I_i`.
  package var receiver: UInt32
  package var ephemeral: InlineArray<32, UInt8>
  package var encryptedEmpty: InlineArray<16, UInt8>
  package var mac1: InlineArray<16, UInt8>
  package var mac2: InlineArray<16, UInt8>

  package init(
    sender: UInt32,
    receiver: UInt32,
    ephemeral: InlineArray<32, UInt8>,
    encryptedEmpty: InlineArray<16, UInt8>,
    mac1: InlineArray<16, UInt8>,
    mac2: InlineArray<16, UInt8>,
  ) {
    self.sender = sender
    self.receiver = receiver
    self.ephemeral = ephemeral
    self.encryptedEmpty = encryptedEmpty
    self.mac1 = mac1
    self.mac2 = mac2
  }

  package init(parsing message: RawSpan) throws(MessageError) {
    guard message.byteCount == Self.byteCount else {
      throw .wrongLength
    }
    try message.checkHeader(.handshakeResponse)
    sender = message.loadLittleEndian(fromByteOffset: 4, as: UInt32.self)
    receiver = message.loadLittleEndian(fromByteOffset: 8, as: UInt32.self)
    ephemeral = message.loadBytes(fromByteOffset: 12)
    encryptedEmpty = message.loadBytes(fromByteOffset: 44)
    mac1 = message.loadBytes(fromByteOffset: 60)
    mac2 = message.loadBytes(fromByteOffset: 76)
  }

  /// Appends the 92 bytes of the message. The output has room for them.
  package func serialize(into output: inout OutputSpan<UInt8>) {
    precondition(output.freeCapacity >= Self.byteCount, "The output has no room for the message")
    output.append(MessageType.handshakeResponse.rawValue)
    output.append(repeating: 0, count: 3)
    output.appendLittleEndian(sender)
    output.appendLittleEndian(receiver)
    output.append(ephemeral)
    output.append(encryptedEmpty)
    output.append(mac1)
    output.append(mac2)
  }
}
