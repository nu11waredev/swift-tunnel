// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s
import Foundation
import Testing

/// The `blake2s` entries of `testvectors/blake2-kat.json` from the BLAKE2
/// reference repository (github.com/BLAKE2/BLAKE2, which licenses its code under CC0 1.0,
/// the OpenSSL Licence or Apache 2.0, at your choosing): 256 unkeyed and 256 keyed
/// BLAKE2s-256 vectors.
struct KnownAnswerTests {
  struct Vector: Decodable, CustomTestStringConvertible {
    let input: String
    let key: String
    let output: String

    enum CodingKeys: String, CodingKey {
      case input = "in"
      case key
      case output = "out"
    }

    var testDescription: String {
      "\(key.isEmpty ? "unkeyed" : "keyed"), \(input.count / 2) bytes"
    }
  }

  static let vectors: [Vector] = {
    let url = Bundle.module.url(forResource: "blake2s-kat", withExtension: "json")!
    return try! JSONDecoder().decode([Vector].self, from: Data(contentsOf: url))
  }()

  @Test func `vendored file holds 256 unkeyed and 256 keyed vectors`() {
    #expect(Self.vectors.count(where: { $0.key.isEmpty }) == 256)
    #expect(Self.vectors.count(where: { !$0.key.isEmpty }) == 256)
  }

  @Test(arguments: vectors)
  func `matches the reference vector`(vector: Vector) throws {
    let input = [UInt8](hex: vector.input)
    let digest: BLAKE2Digest<32>
    if vector.key.isEmpty {
      digest = BLAKE2s<32>.hash(input.span.bytes)
    } else {
      let key = [UInt8](hex: vector.key)
      var hasher = try KeyedBLAKE2s<32>(key: key.span.bytes)
      hasher.update(input.span.bytes)
      digest = hasher.finalize()
    }
    #expect(digest.hex == vector.output)
  }
}
