// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Testing
import X25519

/// The X25519 vectors of Project Wycheproof, in `Fixtures/x25519_test.json`.
/// `Fixtures/README.md` records the file's source, commit and license.
///
/// Wycheproof gives each vector a `result`. A `valid` vector has one correct
/// shared secret. For an `acceptable` vector a library may either return the
/// listed secret or reject the public key. This library does not reject a
/// public key for lying on the curve's twist or in a non-canonical form, and
/// it reads a non-canonical u-coordinate as its reduced value, which RFC 7748,
/// section 5 defines and section 7 recommends. Its one refusal is the
/// all-zero shared secret that RFC 7748, section 6.1 lets a caller check for.
/// `sharedSecret(with:)` throws it as `X25519SharedSecretError.allZero`. So
/// the library's behavior for each result is:
///
/// - `valid`: the listed shared secret, with no error.
/// - `acceptable` with a non-zero listed secret: the listed secret.
/// - `acceptable` with an all-zero listed secret, which Wycheproof flags
///   `ZeroSharedSecret` and `LowOrderPublic`: `allZero` is thrown, and no
///   secret is returned.
/// - `invalid`: no secret equal to the listed one is returned. The file has no
///   such vector today.
struct WycheproofTests {
  struct File: Decodable {
    let numberOfTests: Int
    let testGroups: [Group]
  }

  struct Group: Decodable {
    let tests: [Vector]
  }

  struct Vector: Decodable, CustomTestStringConvertible {
    let tcId: Int
    let comment: String
    let flags: [String]
    let `public`: String
    let `private`: String
    let shared: String
    let result: String

    var testDescription: String {
      "tcId \(tcId), \(result): \(comment)"
    }

    var isAllZero: Bool {
      shared == String(repeating: "0", count: 64)
    }
  }

  static let file: File = {
    let url = Bundle.module.url(forResource: "x25519_test", withExtension: "json")!
    return try! JSONDecoder().decode(File.self, from: Data(contentsOf: url))
  }()

  static let vectors = file.testGroups.flatMap(\.tests)

  @Test func `the file holds 518 vectors, 264 valid and 254 acceptable`() {
    let results = Dictionary(grouping: Self.vectors, by: \.result).mapValues(\.count)
    #expect(Self.file.numberOfTests == 518)
    #expect(Self.vectors.count == 518)
    #expect(Self.vectors.map(\.tcId) == Array(1 ... 518))
    #expect(results == ["valid": 264, "acceptable": 254])
  }

  @Test func `a listed secret is all zero exactly when the vector is flagged ZeroSharedSecret`() {
    for vector in Self.vectors {
      #expect(
        vector.isAllZero == vector.flags.contains("ZeroSharedSecret"),
        "\(vector.testDescription)",
      )
    }
    #expect(Self.vectors.filter(\.isAllZero).count == 31)
  }

  @Test(arguments: vectors)
  func `the library follows its documented behavior for the vector`(vector: Vector) throws {
    let key = X25519PrivateKey(bytes: InlineArray(hex: vector.private))
    let peer = X25519PublicKey(bytes: InlineArray(hex: vector.public))
    switch (vector.result, vector.isAllZero) {
    case ("valid", false), ("acceptable", false):
      let secret = try key.sharedSecret(with: peer)
      #expect(secret.span.hex == vector.shared)
    case ("acceptable", true):
      #expect(throws: X25519SharedSecretError.allZero) {
        _ = try key.sharedSecret(with: peer)
      }
    case ("invalid", _):
      if let secret = try? key.sharedSecret(with: peer) {
        #expect(secret.span.hex != vector.shared)
      }
    default:
      Issue.record("\(vector.testDescription) has a result the mapping does not cover")
    }
  }
}
