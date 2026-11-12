// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// The cookie reply message of the WireGuard paper, section 5.4.7, 64 bytes:
///
///     type 0x3 (1)  reserved 0 (3)  receiver (4)  nonce (24)
///     cookie (16 + 16)
///
/// The encrypted field holds the ciphertext and its 16-byte tag, the bytes as
/// they travel on the wire.
package struct CookieReply: BitwiseCopyable, Sendable {
  package static let byteCount = 64

  /// The sender index of the handshake message being answered.
  package var receiver: UInt32
  /// The XChaCha20Poly1305 nonce.
  package var nonce: InlineArray<24, UInt8>
  package var encryptedCookie: InlineArray<32, UInt8>

  package init(
    receiver: UInt32,
    nonce: InlineArray<24, UInt8>,
    encryptedCookie: InlineArray<32, UInt8>,
  ) {
    self.receiver = receiver
    self.nonce = nonce
    self.encryptedCookie = encryptedCookie
  }

  package init(parsing message: RawSpan) throws(MessageError) {
    guard message.byteCount == Self.byteCount else {
      throw .wrongLength
    }
    try message.checkHeader(.cookieReply)
    receiver = message.loadLittleEndian(fromByteOffset: 4, as: UInt32.self)
    nonce = message.loadBytes(fromByteOffset: 8)
    encryptedCookie = message.loadBytes(fromByteOffset: 32)
  }

  /// Appends the 64 bytes of the message. The output has room for them.
  package func serialize(into output: inout OutputSpan<UInt8>) {
    precondition(output.freeCapacity >= Self.byteCount, "The output has no room for the message")
    output.append(MessageType.cookieReply.rawValue)
    output.append(repeating: 0, count: 3)
    output.appendLittleEndian(receiver)
    output.append(nonce)
    output.append(encryptedCookie)
  }
}
