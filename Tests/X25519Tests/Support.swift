// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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

extension InlineArray where Element == UInt8 {
  init(hex: String) {
    let bytes = [UInt8](hex: hex)
    precondition(bytes.count == count, "The hex string is not \(count) bytes")
    self.init { bytes[$0] }
  }

  init(_ span: Span<UInt8>) {
    precondition(span.count == count, "The span is not \(count) bytes")
    self.init { span[$0] }
  }
}

extension Span where Element == UInt8 {
  var hex: String {
    var bytes: [UInt8] = []
    for index in indices {
      bytes.append(self[index])
    }
    return bytes.hex
  }
}
