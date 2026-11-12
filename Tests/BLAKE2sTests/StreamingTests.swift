// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s
import Testing

/// Splitting the input across updates never changes the digest. Expected
/// values are from Python's hashlib for the same message and key.
struct StreamingTests {
  static let message: [UInt8] = (0 ..< 1100).map { UInt8(truncatingIfNeeded: $0 * 7 + 3) }
  static let key: [UInt8] = Array(0 ..< 32)
  static let unkeyedDigest = "ae775a94bb0376805a2f57a287b4af108f4e5d0f5d806dba305ee961b917557e"
  static let keyedDigest = "3bacf8e8612451cab388e109a010bdf0ab906cd1c57787119c89b706c4d5fb2a"

  /// Three-way splits with each cut just before, on or just after a block boundary.
  static let threeWaySplits: [(Int, Int)] = {
    let firstCuts = [0, 1, 63, 64, 65]
    let secondCuts = [127, 128, 129, 1087, 1088, 1089]
    return firstCuts.flatMap { first in secondCuts.map { (first, $0) } }
  }()

  @Test func `one-shot digests match hashlib`() throws {
    #expect(BLAKE2s<32>.hash(Self.message.span.bytes).hex == Self.unkeyedDigest)
    var keyed = try KeyedBLAKE2s<32>(key: Self.key.span.bytes)
    keyed.update(Self.message.span.bytes)
    #expect(keyed.finalize().hex == Self.keyedDigest)
  }

  @Test func `every two-way split gives the one-shot digest`() throws {
    for cut in 0 ... Self.message.count {
      let parts = [Self.message[..<cut], Self.message[cut...]].map(Array.init)
      #expect(try unkeyedHex(parts) == Self.unkeyedDigest, "cut at \(cut)")
      #expect(try keyedHex(parts) == Self.keyedDigest, "cut at \(cut)")
    }
  }

  @Test(arguments: threeWaySplits)
  func `three-way splits around block boundaries give the one-shot digest`(
    first: Int,
    second: Int,
  ) throws {
    let parts = [
      Self.message[..<first], Self.message[first ..< second], Self.message[second...],
    ].map(Array.init)
    #expect(try unkeyedHex(parts) == Self.unkeyedDigest)
    #expect(try keyedHex(parts) == Self.keyedDigest)
  }

  private func unkeyedHex(_ parts: [[UInt8]]) throws -> String {
    var hasher = BLAKE2s<32>()
    for part in parts {
      hasher.update(part.span.bytes)
    }
    return hasher.finalize().hex
  }

  private func keyedHex(_ parts: [[UInt8]]) throws -> String {
    var hasher = try KeyedBLAKE2s<32>(key: Self.key.span.bytes)
    for part in parts {
      hasher.update(part.span.bytes)
    }
    return hasher.finalize().hex
  }
}
