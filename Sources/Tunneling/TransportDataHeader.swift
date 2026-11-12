// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// The 16-byte header of a transport data message, the WireGuard paper,
/// section 5.4.6:
///
///     type 0x4 (1)  reserved 0 (3)  receiver (4)  counter (8)
///     packet (the padded packet + 16)
///
/// The encrypted packet follows the header and runs to the end of the
/// message. It is at least the 16-byte tag, which is all a keepalive carries,
/// so a message is at least 32 bytes.
package struct TransportDataHeader: BitwiseCopyable, Sendable {
  package static let byteCount = 16
  package static let minimumMessageByteCount = 32

  /// The index the receiving peer chose for the session.
  package var receiver: UInt32
  /// The sender's message counter, the AEAD nonce for the packet.
  package var counter: UInt64

  package init(receiver: UInt32, counter: UInt64) {
    self.receiver = receiver
    self.counter = counter
  }

  /// Reads the header of a whole message, header and encrypted packet.
  package init(parsing message: RawSpan) throws(MessageError) {
    guard message.byteCount >= Self.minimumMessageByteCount else {
      throw .wrongLength
    }
    try message.checkHeader(.transportData)
    receiver = message.loadLittleEndian(fromByteOffset: 4, as: UInt32.self)
    counter = message.loadLittleEndian(fromByteOffset: 8, as: UInt64.self)
  }

  /// Appends the 16 header bytes. The encrypted packet goes after them.
  package func serialize(into output: inout OutputSpan<UInt8>) {
    precondition(output.freeCapacity >= Self.byteCount, "The output has no room for the header")
    output.append(MessageType.transportData.rawValue)
    output.append(repeating: 0, count: 3)
    output.appendLittleEndian(receiver)
    output.appendLittleEndian(counter)
  }
}
