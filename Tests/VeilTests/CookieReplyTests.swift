// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import Veil

/// The cookie reply of the WireGuard paper, section 5.4.7.
struct CookieReplyTests {
  @Test(arguments: MessageFixtures.file.cookieReply)
  func `a cookie reply parses to the fields packed by Python`(
    fixture: MessageFixtures.CookieReply,
  ) throws {
    let bytes = [UInt8](hex: fixture.message)
    let message = try CookieReply(parsing: bytes.span.bytes)
    #expect(message.receiver == fixture.receiver)
    #expect(message.nonce.hex == fixture.nonce)
    #expect(message.encryptedCookie.hex == fixture.encryptedCookie)
  }

  @Test(arguments: MessageFixtures.file.cookieReply)
  func `a cookie reply serializes to the bytes packed by Python`(
    fixture: MessageFixtures.CookieReply,
  ) {
    let message = CookieReply(
      receiver: fixture.receiver,
      nonce: InlineArray(hex: fixture.nonce),
      encryptedCookie: InlineArray(hex: fixture.encryptedCookie),
    )
    let bytes = [UInt8](capacity: CookieReply.byteCount) { output in
      message.serialize(into: &output)
    }
    #expect(bytes.hex == fixture.message)
  }

  @Test(arguments: [0, 1, 4, 63, 65, 92])
  func `a cookie reply of another length throws`(count: Int) {
    let whole = [UInt8](hex: MessageFixtures.file.cookieReply[0].message)
    let bytes = (0 ..< count).map { whole[$0 % whole.count] }
    #expect(throws: MessageError.wrongLength) {
      _ = try CookieReply(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: [1, 2, 4] as [UInt8])
  func `a cookie reply with another message's type byte throws`(type: UInt8) {
    var bytes = [UInt8](hex: MessageFixtures.file.cookieReply[0].message)
    bytes[0] = type
    #expect(throws: MessageError.wrongType) {
      _ = try CookieReply(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: [0, 5, 0x83, 0xFF] as [UInt8])
  func `a cookie reply with a type byte that names no message throws`(type: UInt8) {
    var bytes = [UInt8](hex: MessageFixtures.file.cookieReply[0].message)
    bytes[0] = type
    #expect(throws: MessageError.unknownType) {
      _ = try CookieReply(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: 1 ... 3)
  func `a cookie reply with a reserved byte set throws`(offset: Int) {
    var bytes = [UInt8](hex: MessageFixtures.file.cookieReply[0].message)
    bytes[offset] = 0xFF
    #expect(throws: MessageError.nonzeroReserved) {
      _ = try CookieReply(parsing: bytes.span.bytes)
    }
  }
}
