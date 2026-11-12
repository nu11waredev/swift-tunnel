// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import Veil

/// The handshake response of the WireGuard paper, section 5.4.3.
struct HandshakeResponseTests {
  @Test(arguments: MessageFixtures.file.response)
  func `a response parses to the fields packed by Python`(
    fixture: MessageFixtures.Response,
  ) throws {
    let bytes = [UInt8](hex: fixture.message)
    let message = try HandshakeResponse(parsing: bytes.span.bytes)
    #expect(message.sender == fixture.sender)
    #expect(message.receiver == fixture.receiver)
    #expect(message.ephemeral.hex == fixture.ephemeral)
    #expect(message.encryptedEmpty.hex == fixture.encryptedEmpty)
    #expect(message.mac1.hex == fixture.mac1)
    #expect(message.mac2.hex == fixture.mac2)
  }

  @Test(arguments: MessageFixtures.file.response)
  func `a response serializes to the bytes packed by Python`(
    fixture: MessageFixtures.Response,
  ) {
    let message = HandshakeResponse(
      sender: fixture.sender,
      receiver: fixture.receiver,
      ephemeral: InlineArray(hex: fixture.ephemeral),
      encryptedEmpty: InlineArray(hex: fixture.encryptedEmpty),
      mac1: InlineArray(hex: fixture.mac1),
      mac2: InlineArray(hex: fixture.mac2),
    )
    let bytes = [UInt8](capacity: HandshakeResponse.byteCount) { output in
      message.serialize(into: &output)
    }
    #expect(bytes.hex == fixture.message)
  }

  @Test(arguments: MessageFixtures.file.response)
  func `a response's MACs cover the bytes before each MAC`(
    fixture: MessageFixtures.Response,
  ) {
    let bytes = [UInt8](hex: fixture.message)
    #expect(Array(bytes[HandshakeResponse.mac1CoveredBytes]).hex == fixture.mac1Input)
    #expect(Array(bytes[HandshakeResponse.mac2CoveredBytes]).hex == fixture.mac2Input)
  }

  @Test(arguments: [0, 1, 4, 91, 93, 148])
  func `a response of another length throws`(count: Int) {
    let whole = [UInt8](hex: MessageFixtures.file.response[0].message)
    let bytes = (0 ..< count).map { whole[$0 % whole.count] }
    #expect(throws: MessageError.wrongLength) {
      _ = try HandshakeResponse(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: [1, 3, 4] as [UInt8])
  func `a response with another message's type byte throws`(type: UInt8) {
    var bytes = [UInt8](hex: MessageFixtures.file.response[0].message)
    bytes[0] = type
    #expect(throws: MessageError.wrongType) {
      _ = try HandshakeResponse(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: [0, 5, 0x82, 0xFF] as [UInt8])
  func `a response with a type byte that names no message throws`(type: UInt8) {
    var bytes = [UInt8](hex: MessageFixtures.file.response[0].message)
    bytes[0] = type
    #expect(throws: MessageError.unknownType) {
      _ = try HandshakeResponse(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: 1 ... 3)
  func `a response with a reserved byte set throws`(offset: Int) {
    var bytes = [UInt8](hex: MessageFixtures.file.response[0].message)
    bytes[offset] = 0x80
    #expect(throws: MessageError.nonzeroReserved) {
      _ = try HandshakeResponse(parsing: bytes.span.bytes)
    }
  }
}
