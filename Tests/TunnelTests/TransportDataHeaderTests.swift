// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing
import Tunnel

/// The transport data message of the WireGuard paper, section 5.4.6.
struct TransportDataHeaderTests {
  @Test(arguments: MessageFixtures.file.transportData)
  func `a transport data header parses to the fields packed by Python`(
    fixture: MessageFixtures.TransportData,
  ) throws {
    let bytes = [UInt8](hex: fixture.message)
    let header = try TransportDataHeader(parsing: bytes.span.bytes)
    #expect(header.receiver == fixture.receiver)
    #expect(header.counter == fixture.counter)
    #expect(Array(bytes[TransportDataHeader.byteCount...]).hex == fixture.packet)
  }

  @Test(arguments: MessageFixtures.file.transportData)
  func `a header and its packet serialize to the bytes packed by Python`(
    fixture: MessageFixtures.TransportData,
  ) {
    let header = TransportDataHeader(receiver: fixture.receiver, counter: fixture.counter)
    let packet = [UInt8](hex: fixture.packet)
    let bytes = [UInt8](capacity: TransportDataHeader.byteCount + packet.count) { output in
      header.serialize(into: &output)
      for byte in packet {
        output.append(byte)
      }
    }
    #expect(bytes.hex == fixture.message)
  }

  @Test(arguments: [0, 1, 4, 16, 31])
  func `a transport data message shorter than 32 bytes throws`(count: Int) {
    let whole = [UInt8](hex: MessageFixtures.file.transportData[0].message)
    let bytes = Array(whole[0 ..< count])
    #expect(throws: MessageError.wrongLength) {
      _ = try TransportDataHeader(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: [1, 2, 3] as [UInt8])
  func `a transport data message with another message's type byte throws`(type: UInt8) {
    var bytes = [UInt8](hex: MessageFixtures.file.transportData[0].message)
    bytes[0] = type
    #expect(throws: MessageError.wrongType) {
      _ = try TransportDataHeader(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: [0, 5, 0x84, 0xFF] as [UInt8])
  func `a transport data message with a type byte that names no message throws`(type: UInt8) {
    var bytes = [UInt8](hex: MessageFixtures.file.transportData[0].message)
    bytes[0] = type
    #expect(throws: MessageError.unknownType) {
      _ = try TransportDataHeader(parsing: bytes.span.bytes)
    }
  }

  @Test(arguments: 1 ... 3)
  func `a transport data message with a reserved byte set throws`(offset: Int) {
    var bytes = [UInt8](hex: MessageFixtures.file.transportData[0].message)
    bytes[offset] = 0x10
    #expect(throws: MessageError.nonzeroReserved) {
      _ = try TransportDataHeader(parsing: bytes.span.bytes)
    }
  }
}
