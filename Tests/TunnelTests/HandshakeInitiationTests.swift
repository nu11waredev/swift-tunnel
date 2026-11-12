// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import Tunnel

/// The handshake initiation of the WireGuard paper, section 5.4.2.
struct HandshakeInitiationTests {
  @Test(arguments: MessageFixtures.file.initiation)
  func `an initiation parses to the fields packed by Python`(
    fixture: MessageFixtures.Initiation,
  ) throws {
    let bytes = [UInt8](hex: fixture.message)
    let message = try HandshakeInitiation(parsing: bytes.span.bytes)
    #expect(message.sender == fixture.sender)
    #expect(message.ephemeral.hex == fixture.ephemeral)
    #expect(message.encryptedStatic.hex == fixture.encryptedStatic)
    #expect(message.encryptedTimestamp.hex == fixture.encryptedTimestamp)
    #expect(message.mac1.hex == fixture.mac1)
    #expect(message.mac2.hex == fixture.mac2)
  }

  @Test(arguments: MessageFixtures.file.initiation)
  func `an initiation serializes to the bytes packed by Python`(
    fixture: MessageFixtures.Initiation,
  ) {
    let message = HandshakeInitiation(
      sender: fixture.sender,
      ephemeral: InlineArray(hex: fixture.ephemeral),
      encryptedStatic: InlineArray(hex: fixture.encryptedStatic),
      encryptedTimestamp: InlineArray(hex: fixture.encryptedTimestamp),
      mac1: InlineArray(hex: fixture.mac1),
      mac2: InlineArray(hex: fixture.mac2),
    )
    let bytes = [UInt8](capacity: HandshakeInitiation.byteCount) { output in
      message.serialize(into: &output)
    }
    #expect(bytes.hex == fixture.message)
  }

  @Test(arguments: MessageFixtures.file.initiation)
  func `an initiation's MACs cover the bytes before each MAC`(
    fixture: MessageFixtures.Initiation,
  ) {
    let bytes = [UInt8](hex: fixture.message)
    #expect(Array(bytes[HandshakeInitiation.mac1CoveredBytes]).hex == fixture.mac1Input)
    #expect(Array(bytes[HandshakeInitiation.mac2CoveredBytes]).hex == fixture.mac2Input)
  }

  @Test(arguments: [0, 1, 4, 92, 147, 149, 296])
  func `an initiation of another length throws`(count: Int) {
    let whole = [UInt8](hex: MessageFixtures.file.initiation[0].message)
    let bytes = (0 ..< count).map { whole[$0 % whole.count] }
    #expect(throws: MessageError.wrongLength) {
      _ = try HandshakeInitiation(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: [2, 3, 4] as [UInt8])
  func `an initiation with another message's type byte throws`(type: UInt8) {
    var bytes = [UInt8](hex: MessageFixtures.file.initiation[0].message)
    bytes[0] = type
    #expect(throws: MessageError.wrongType) {
      _ = try HandshakeInitiation(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: [0, 5, 0x81, 0xFF] as [UInt8])
  func `an initiation with a type byte that names no message throws`(type: UInt8) {
    var bytes = [UInt8](hex: MessageFixtures.file.initiation[0].message)
    bytes[0] = type
    #expect(throws: MessageError.unknownType) {
      _ = try HandshakeInitiation(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: 1 ... 3)
  func `an initiation with a reserved byte set throws`(offset: Int) {
    var bytes = [UInt8](hex: MessageFixtures.file.initiation[0].message)
    bytes[offset] = 0x01
    #expect(throws: MessageError.nonzeroReserved) {
      _ = try HandshakeInitiation(parsing: bytes.span.bytes)
    }
  }
}
