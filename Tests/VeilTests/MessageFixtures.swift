// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Testing

/// Messages packed by Python's struct module from the field tables of the
/// WireGuard paper, section 5.4, written by `Fixtures/generate_messages.py`.
struct MessageFixtures: Decodable {
  let initiation: [Initiation]
  let response: [Response]
  let cookieReply: [CookieReply]
  let transportData: [TransportData]

  struct Initiation: Decodable, CustomTestStringConvertible {
    let message: String
    let sender: UInt32
    let ephemeral: String
    let encryptedStatic: String
    let encryptedTimestamp: String
    let mac1: String
    let mac2: String
    let mac1Input: String
    let mac2Input: String

    var testDescription: String {
      "sender \(sender)"
    }
  }

  struct Response: Decodable, CustomTestStringConvertible {
    let message: String
    let sender: UInt32
    let receiver: UInt32
    let ephemeral: String
    let encryptedEmpty: String
    let mac1: String
    let mac2: String
    let mac1Input: String
    let mac2Input: String

    var testDescription: String {
      "sender \(sender), receiver \(receiver)"
    }
  }

  struct CookieReply: Decodable, CustomTestStringConvertible {
    let message: String
    let receiver: UInt32
    let nonce: String
    let encryptedCookie: String

    var testDescription: String {
      "receiver \(receiver)"
    }
  }

  struct TransportData: Decodable, CustomTestStringConvertible {
    let message: String
    let receiver: UInt32
    let counter: UInt64
    let packet: String

    var testDescription: String {
      "counter \(counter), \(packet.count / 2)-byte packet"
    }
  }

  static let file: MessageFixtures = {
    let url = Bundle.module.url(forResource: "message-fixtures", withExtension: "json")!
    return try! JSONDecoder().decode(MessageFixtures.self, from: Data(contentsOf: url))
  }()
}
