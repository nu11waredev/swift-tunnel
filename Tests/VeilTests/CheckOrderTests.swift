// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import Veil

/// A parse checks the length first, then the type byte, then the reserved
/// bytes.
struct CheckOrderTests {
  /// Each message type with a length that is wrong for it.
  static let wrongLengths: [(MessageType, Int)] = [
    (.handshakeInitiation, HandshakeInitiation.byteCount + 1),
    (.handshakeResponse, HandshakeResponse.byteCount - 1),
    (.cookieReply, CookieReply.byteCount + 1),
    (.transportData, TransportDataHeader.minimumMessageByteCount - 1),
  ]

  /// Each message type with a length that is right for it.
  static let rightLengths: [(MessageType, Int)] = [
    (.handshakeInitiation, HandshakeInitiation.byteCount),
    (.handshakeResponse, HandshakeResponse.byteCount),
    (.cookieReply, CookieReply.byteCount),
    (.transportData, TransportDataHeader.minimumMessageByteCount),
  ]

  static func parse(_ type: MessageType, _ bytes: [UInt8]) throws(MessageError) {
    switch type {
    case .handshakeInitiation: _ = try HandshakeInitiation(parsing: bytes.span.bytes)
    case .handshakeResponse: _ = try HandshakeResponse(parsing: bytes.span.bytes)
    case .cookieReply: _ = try CookieReply(parsing: bytes.span.bytes)
    case .transportData: _ = try TransportDataHeader(parsing: bytes.span.bytes)
    }
  }

  /// Bytes that start with `first` and have all three reserved bytes set.
  static func bytes(first: UInt8, count: Int) -> [UInt8] {
    [first, 0xFF, 0xFF, 0xFF] + [UInt8](repeating: 0, count: count - 4)
  }

  @Test(arguments: wrongLengths)
  func `a wrong length is reported before a bad type and set reserved bytes`(
    type: MessageType,
    count: Int,
  ) {
    let bytes = Self.bytes(first: 0x7F, count: count)
    #expect(throws: MessageError.wrongLength) {
      try Self.parse(type, bytes)
    }
  }

  @Test(arguments: rightLengths)
  func `a type that names no message is reported before set reserved bytes`(
    type: MessageType,
    count: Int,
  ) {
    let bytes = Self.bytes(first: 0x7F, count: count)
    #expect(throws: MessageError.unknownType) {
      try Self.parse(type, bytes)
    }
  }

  @Test(arguments: rightLengths)
  func `another message's type is reported before set reserved bytes`(
    type: MessageType,
    count: Int,
  ) {
    let other: MessageType = type == .cookieReply ? .transportData : .cookieReply
    let bytes = Self.bytes(first: other.rawValue, count: count)
    #expect(throws: MessageError.wrongType) {
      try Self.parse(type, bytes)
    }
  }
}
