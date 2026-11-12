// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// An element of GF(p), p = 2^255 - 19, as five limbs of radix 2^51:
///
///     value = l0 + l1 * 2^51 + l2 * 2^102 + l3 * 2^153 + l4 * 2^204
///
/// Fifty-one bits leave thirteen spare bits in each `UInt64`, so sums and
/// differences need no carry, and the 102-bit product of two limbs, summed
/// five at a time, fits a `UInt128` with room to spare. A limb above 51 bits
/// is allowed between operations: `multiplied(by:)` accepts limbs below 2^54
/// and returns limbs below 2^52, and `subtracting(_:)` takes a subtrahend with
/// limbs below 2^52.
///
/// Every operation runs the same instructions whatever the value, and reads and
/// writes the same memory. The arithmetic uses the wrapping operators, which
/// compile to plain machine adds, subtracts and multiplies, and the bounds
/// above keep every result in range.
struct FieldElement: BitwiseCopyable {
  var l0: UInt64
  var l1: UInt64
  var l2: UInt64
  var l3: UInt64
  var l4: UInt64

  static let mask: UInt64 = (1 << 51) - 1

  static let zero = FieldElement(l0: 0, l1: 0, l2: 0, l3: 0, l4: 0)
  static let one = FieldElement(l0: 1, l1: 0, l2: 0, l3: 0, l4: 0)

  /// Decodes a little-endian u-coordinate (RFC 7748, section 5), ignoring bit
  /// 255. A value from p to 2^255 - 1 is kept as it is, and the arithmetic
  /// treats it as the value reduced modulo p.
  init(bytes: InlineArray<32, UInt8>) {
    let w0 = Self.word(bytes, at: 0)
    let w1 = Self.word(bytes, at: 8)
    let w2 = Self.word(bytes, at: 16)
    let w3 = Self.word(bytes, at: 24)
    l0 = w0 & Self.mask
    l1 = (w0 >> 51 | w1 << 13) & Self.mask
    l2 = (w1 >> 38 | w2 << 26) & Self.mask
    l3 = (w2 >> 25 | w3 << 39) & Self.mask
    // Bits 12 to 62 of the last word. Bit 63, bit 255 of the input, is dropped.
    l4 = (w3 >> 12) & Self.mask
  }

  init(l0: UInt64, l1: UInt64, l2: UInt64, l3: UInt64, l4: UInt64) {
    self.l0 = l0
    self.l1 = l1
    self.l2 = l2
    self.l3 = l3
    self.l4 = l4
  }

  /// The canonical encoding: the value reduced to 0 ... p - 1, little-endian,
  /// with bit 255 clear.
  var bytes: InlineArray<32, UInt8> {
    var h = carried().carried()
    // Now every limb is at most 2^51, so h is below 2p. h >= p exactly when
    // h + 19 reaches 2^255, and the carry out of the top limb of h + 19 is
    // that bit.
    var q = (h.l0 &+ 19) >> 51
    q = (h.l1 &+ q) >> 51
    q = (h.l2 &+ q) >> 51
    q = (h.l3 &+ q) >> 51
    q = (h.l4 &+ q) >> 51
    // Subtracting qp is adding 19q and dropping 2^255.
    h.l0 &+= 19 &* q
    h.l1 &+= h.l0 >> 51
    h.l0 &= Self.mask
    h.l2 &+= h.l1 >> 51
    h.l1 &= Self.mask
    h.l3 &+= h.l2 >> 51
    h.l2 &= Self.mask
    h.l4 &+= h.l3 >> 51
    h.l3 &= Self.mask
    h.l4 &= Self.mask

    let w0 = h.l0 | h.l1 << 51
    let w1 = h.l1 >> 13 | h.l2 << 38
    let w2 = h.l2 >> 26 | h.l3 << 25
    let w3 = h.l3 >> 39 | h.l4 << 12
    return InlineArray { index in
      let word =
        switch index >> 3 {
        case 0: w0
        case 1: w1
        case 2: w2
        default: w3
        }
      return UInt8(truncatingIfNeeded: word >> (8 &* (index & 7)))
    }
  }

  func adding(_ other: Self) -> Self {
    Self(
      l0: l0 &+ other.l0,
      l1: l1 &+ other.l1,
      l2: l2 &+ other.l2,
      l3: l3 &+ other.l3,
      l4: l4 &+ other.l4,
    )
  }

  /// `self - other`, computed as `self + 4p - other` so no limb goes below
  /// zero, then carried. Every subtrahend the ladder passes is an output of
  /// `multiplied(by:)` or the starting zero or one, so the limbs of `other`
  /// are below 2^52, and the limbs of 4p, at least 2^53 - 76, cover them.
  func subtracting(_ other: Self) -> Self {
    // 4p in radix 2^51: 2^53 - 76 in the lowest limb, 2^53 - 4 in the rest.
    Self(
      l0: l0 &+ 0x1F_FFFF_FFFF_FFB4 &- other.l0,
      l1: l1 &+ 0x1F_FFFF_FFFF_FFFC &- other.l1,
      l2: l2 &+ 0x1F_FFFF_FFFF_FFFC &- other.l2,
      l3: l3 &+ 0x1F_FFFF_FFFF_FFFC &- other.l3,
      l4: l4 &+ 0x1F_FFFF_FFFF_FFFC &- other.l4,
    ).carried()
  }

  /// The product modulo p. A partial product of limbs i and j weighs
  /// 2^(51(i + j)). From i + j = 5 on, that is 2^255 * 2^(51(i + j - 5)), and
  /// 2^255 = 19 modulo p, so those products fold into the low limbs times 19.
  func multiplied(by other: Self) -> Self {
    let a0 = UInt128(l0), a1 = UInt128(l1), a2 = UInt128(l2)
    let a3 = UInt128(l3), a4 = UInt128(l4)
    let b0 = UInt128(other.l0), b1 = UInt128(other.l1), b2 = UInt128(other.l2)
    let b3 = UInt128(other.l3), b4 = UInt128(other.l4)
    let c1 = 19 &* b1, c2 = 19 &* b2, c3 = 19 &* b3, c4 = 19 &* b4

    let r0 = a0 &* b0 &+ a1 &* c4 &+ a2 &* c3 &+ a3 &* c2 &+ a4 &* c1
    let r1 = a0 &* b1 &+ a1 &* b0 &+ a2 &* c4 &+ a3 &* c3 &+ a4 &* c2
    let r2 = a0 &* b2 &+ a1 &* b1 &+ a2 &* b0 &+ a3 &* c4 &+ a4 &* c3
    let r3 = a0 &* b3 &+ a1 &* b2 &+ a2 &* b1 &+ a3 &* b0 &+ a4 &* c4
    let r4 = a0 &* b4 &+ a1 &* b3 &+ a2 &* b2 &+ a3 &* b1 &+ a4 &* b0
    return Self.carried(r0, r1, r2, r3, r4)
  }

  func squared() -> Self {
    multiplied(by: self)
  }

  /// `self` squared `count` times. The count is a public constant.
  func squared(times count: Int) -> Self {
    var result = self
    for _ in 0 ..< count {
      result = result.squared()
    }
    return result
  }

  /// The product with a constant below 2^17.
  func multiplied(bySmall factor: UInt64) -> Self {
    let k = UInt128(factor)
    return Self.carried(
      UInt128(l0) &* k,
      UInt128(l1) &* k,
      UInt128(l2) &* k,
      UInt128(l3) &* k,
      UInt128(l4) &* k,
    )
  }

  /// The inverse, as self^(p - 2) by Fermat's little theorem. Zero maps to
  /// zero.
  ///
  /// p - 2 = 2^255 - 21 = (2^250 - 1) * 2^5 + 11. Writing t(n) for
  /// self^(2^n - 1), squaring t(n) m times and multiplying by t(m) gives
  /// t(n + m), which builds t(250) from t(5) in eight steps.
  func inverted() -> Self {
    let z2 = squared()
    let z9 = z2.squared(times: 2).multiplied(by: self)
    let z11 = z9.multiplied(by: z2)
    let t5 = z11.squared().multiplied(by: z9)
    let t10 = t5.squared(times: 5).multiplied(by: t5)
    let t20 = t10.squared(times: 10).multiplied(by: t10)
    let t40 = t20.squared(times: 20).multiplied(by: t20)
    let t50 = t40.squared(times: 10).multiplied(by: t10)
    let t100 = t50.squared(times: 50).multiplied(by: t50)
    let t200 = t100.squared(times: 100).multiplied(by: t100)
    let t250 = t200.squared(times: 50).multiplied(by: t50)
    return t250.squared(times: 5).multiplied(by: z11)
  }

  /// Exchanges `a` and `b` when `bit` is 1 and leaves them when it is 0, by
  /// masking, with the same instructions either way.
  static func conditionalSwap(_ a: inout Self, _ b: inout Self, bit: UInt64) {
    let mask = 0 &- bit
    var d = mask & (a.l0 ^ b.l0)
    a.l0 ^= d
    b.l0 ^= d
    d = mask & (a.l1 ^ b.l1)
    a.l1 ^= d
    b.l1 ^= d
    d = mask & (a.l2 ^ b.l2)
    a.l2 ^= d
    b.l2 ^= d
    d = mask & (a.l3 ^ b.l3)
    a.l3 ^= d
    b.l3 ^= d
    d = mask & (a.l4 ^ b.l4)
    a.l4 ^= d
    b.l4 ^= d
  }

  /// One carry pass: each limb keeps its low 51 bits and passes the rest up,
  /// and the carry out of the top limb comes back into l0 times 19.
  private func carried() -> Self {
    Self.carried(UInt128(l0), UInt128(l1), UInt128(l2), UInt128(l3), UInt128(l4))
  }

  private static func carried(
    _ r0: UInt128,
    _ r1: UInt128,
    _ r2: UInt128,
    _ r3: UInt128,
    _ r4: UInt128,
  ) -> Self {
    let r1 = r1 &+ (r0 >> 51)
    let r2 = r2 &+ (r1 >> 51)
    let r3 = r3 &+ (r2 >> 51)
    let r4 = r4 &+ (r3 >> 51)
    let top = UInt64(truncatingIfNeeded: r4 >> 51)
    var l0 = (UInt64(truncatingIfNeeded: r0) & mask) &+ 19 &* top
    var l1 = UInt64(truncatingIfNeeded: r1) & mask
    l1 &+= l0 >> 51
    l0 &= mask
    return Self(
      l0: l0,
      l1: l1,
      l2: UInt64(truncatingIfNeeded: r2) & mask,
      l3: UInt64(truncatingIfNeeded: r3) & mask,
      l4: UInt64(truncatingIfNeeded: r4) & mask,
    )
  }

  private static func word(_ bytes: InlineArray<32, UInt8>, at offset: Int) -> UInt64 {
    var word: UInt64 = 0
    for index in 0 ..< 8 {
      word |= UInt64(bytes[offset + index]) << (8 * index)
    }
    return word
  }
}
