// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s
import Testing

struct ValidationTests {
  @Test func `an empty key throws`() {
    let key: [UInt8] = []
    #expect(throws: BLAKE2KeyError.invalidLength) {
      _ = try KeyedBLAKE2s<32>(key: key.span.bytes)
    }
  }

  @Test func `a 33-byte key throws`() {
    let key = [UInt8](repeating: 0xA5, count: 33)
    #expect(throws: BLAKE2KeyError.invalidLength) {
      _ = try KeyedBLAKE2s<32>(key: key.span.bytes)
    }
  }

  @Test func `keys of 1 and 32 bytes are accepted`() {
    let shortest = [UInt8](repeating: 0xA5, count: 1)
    let longest = [UInt8](repeating: 0xA5, count: 32)
    #expect(throws: Never.self) {
      _ = try KeyedBLAKE2s<32>(key: shortest.span.bytes)
      _ = try KeyedBLAKE2s<32>(key: longest.span.bytes)
    }
  }

  @Test func `a zero-byte digest traps`() async {
    await #expect(processExitsWith: .failure) {
      _ = BLAKE2s<0>()
    }
  }

  @Test func `a 33-byte digest traps`() async {
    await #expect(processExitsWith: .failure) {
      _ = BLAKE2s<33>()
    }
  }

  @Test func `a keyed hasher with a 33-byte digest traps`() async {
    await #expect(processExitsWith: .failure) {
      let key = [UInt8](repeating: 0xA5, count: 16)
      _ = try? KeyedBLAKE2s<33>(key: key.span.bytes)
    }
  }
}
