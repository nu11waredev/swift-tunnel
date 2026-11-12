// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s

extension BLAKE2Digest {
  var bytes: [UInt8] {
    let span = span
    var bytes: [UInt8] = []
    for index in span.indices {
      bytes.append(span[index])
    }
    return bytes
  }

  var hex: String {
    bytes.hex
  }
}

extension [UInt8] {
  init(hex: String) {
    let digits = Array(hex.utf8)
    self = stride(from: 0, to: digits.count, by: 2).map { index in
      UInt8(String(decoding: digits[index ..< index + 2], as: UTF8.self), radix: 16)!
    }
  }

  var hex: String {
    let digits = Array("0123456789abcdef".utf8)
    var text: [UInt8] = []
    for byte in self {
      text.append(digits[Int(byte >> 4)])
      text.append(digits[Int(byte & 0x0F)])
    }
    return String(decoding: text, as: UTF8.self)
  }
}
