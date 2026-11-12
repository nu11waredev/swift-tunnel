// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BLAKE2s
import Testing

struct RFC7693Tests {
  @Test func `appendix B hash of ABC`() {
    let message: [UInt8] = Array("abc".utf8)
    let digest = BLAKE2s<32>.hash(message.span.bytes)
    #expect(
      digest.hex == "508c5e8c327c14e2e1a72ba34eeb452f37458b209ed63a294d999b4c86675982",
    )
  }

  @Test func `appendix E self-test`() throws {
    var grand = BLAKE2s<32>()
    try appendSelfTestDigests(BLAKE2s<16>.self, to: &grand)
    try appendSelfTestDigests(BLAKE2s<20>.self, to: &grand)
    try appendSelfTestDigests(BLAKE2s<28>.self, to: &grand)
    try appendSelfTestDigests(BLAKE2s<32>.self, to: &grand)
    #expect(
      grand.finalize().hex == "6a411f08ce25adcdfb02aba641451cec53c598b24f4fc787fbdc88797f4c1dfe",
    )
  }
}

/// One digest length of the RFC 7693 appendix E loop: the unkeyed and keyed
/// digests of each input length, fed into the grand hash.
private func appendSelfTestDigests<let digestCount: Int>(
  _: BLAKE2s<digestCount>.Type,
  to grand: inout BLAKE2s<32>,
) throws {
  for inputCount in [0, 3, 64, 65, 255, 1024] {
    let input = selfTestSequence(count: inputCount, seed: UInt32(inputCount))
    grand.update(BLAKE2s<digestCount>.hash(input.span.bytes).span.bytes)

    let key = selfTestSequence(count: digestCount, seed: UInt32(digestCount))
    var keyed = try KeyedBLAKE2s<digestCount>(key: key.span.bytes)
    keyed.update(input.span.bytes)
    grand.update(keyed.finalize().span.bytes)
  }
}

/// `selftest_seq` of RFC 7693 appendix E.
private func selfTestSequence(count: Int, seed: UInt32) -> [UInt8] {
  var a = 0xDEAD_4BAD &* seed
  var b: UInt32 = 1
  return (0 ..< count).map { _ in
    let t = a &+ b
    a = b
    b = t
    return UInt8(t >> 24)
  }
}
