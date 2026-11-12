// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// The four messages of the WireGuard paper, section 5.4, by the value of
/// the byte each one starts with.
package enum MessageType: UInt8, Sendable {
  case handshakeInitiation = 1
  case handshakeResponse = 2
  case cookieReply = 3
  case transportData = 4

  /// The type of a message, from its first byte. The rest of the message is
  /// checked when it is parsed as that type.
  package init(of message: RawSpan) throws(MessageError) {
    guard !message.isEmpty else {
      throw .wrongLength
    }
    guard let type = Self(rawValue: message.unsafeLoad(as: UInt8.self)) else {
      throw .unknownType
    }
    self = type
  }
}
