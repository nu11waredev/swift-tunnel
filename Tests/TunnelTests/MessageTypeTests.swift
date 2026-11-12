// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import Tunnel

/// Telling the four messages of the WireGuard paper, section 5.4, apart.
struct MessageTypeTests {
  @Test func `each message packed by Python reads as its type`() throws {
    let file = MessageFixtures.file
    let cases: [(String, MessageType)] =
      file.initiation.map { ($0.message, .handshakeInitiation) }
        + file.response.map { ($0.message, .handshakeResponse) }
        + file.cookieReply.map { ($0.message, .cookieReply) }
        + file.transportData.map { ($0.message, .transportData) }
    for (message, expected) in cases {
      let bytes = [UInt8](hex: message)
      #expect(try MessageType(of: bytes.span.bytes) == expected)
    }
  }

  @Test(arguments: [0, 5, 6, 0x81, 0xFF] as [UInt8])
  func `a first byte that names no message throws`(type: UInt8) {
    let bytes = [type, 0, 0, 0]
    #expect(throws: MessageError.unknownType) {
      _ = try MessageType(of: bytes.span.bytes)
    }
  }

  @Test func `no bytes throws`() {
    let bytes: [UInt8] = []
    #expect(throws: MessageError.wrongLength) {
      _ = try MessageType(of: bytes.span.bytes)
    }
  }
}
