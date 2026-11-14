// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// The X25519 function of RFC 7748, section 5: the scalar, clamped, times the
/// point with u-coordinate `u`, by the Montgomery ladder.
///
/// The ladder runs the same field operations, in the same order, for every
/// scalar and every u-coordinate. A scalar bit chooses which pair of
/// coordinates is worked on only through `FieldElement.conditionalSwap`, and
/// the loop visits bits 254 down to 0 in a fixed order. Every named value that
/// depends on the scalar is zeroized before it returns: the clamped copy of the
/// scalar, the bit and swap values, the coordinates, the values of the last
/// step, the powers the inversion names, the inverse and the product that
/// becomes the result. `x1`, a copy of the public u-coordinate, and the
/// returned bytes are not.
/// Registers and temporary stack slots that the compiler uses are not
/// reachable from Swift and are not wiped, and neither is the caller's own
/// copy of `scalar`.
func x25519(
  scalar: InlineArray<32, UInt8>,
  u: InlineArray<32, UInt8>,
) -> InlineArray<32, UInt8> {
  var k = scalar
  clamp(&k)
  let x1 = FieldElement(bytes: u)
  var x2 = FieldElement.one
  var z2 = FieldElement.zero
  var x3 = x1
  var z3 = FieldElement.one
  var swap: UInt64 = 0
  var bit: UInt64 = 0

  // Declared outside the loop so the values of the last step can be zeroized.
  var a = FieldElement.zero, aa = FieldElement.zero
  var b = FieldElement.zero, bb = FieldElement.zero
  var e = FieldElement.zero
  var c = FieldElement.zero, d = FieldElement.zero
  var da = FieldElement.zero, cb = FieldElement.zero

  for t in (0 ..< 255).reversed() {
    bit = UInt64(k[t >> 3] >> UInt8(t & 7)) & 1
    swap ^= bit
    FieldElement.conditionalSwap(&x2, &x3, bit: swap)
    FieldElement.conditionalSwap(&z2, &z3, bit: swap)
    swap = bit

    a = x2.adding(z2)
    aa = a.squared()
    b = x2.subtracting(z2)
    bb = b.squared()
    e = aa.subtracting(bb)
    c = x3.adding(z3)
    d = x3.subtracting(z3)
    da = d.multiplied(by: a)
    cb = c.multiplied(by: b)
    x3 = da.adding(cb).squared()
    z3 = x1.multiplied(by: da.subtracting(cb).squared())
    x2 = aa.multiplied(by: bb)
    // a24 = (486662 - 2) / 4.
    z2 = e.multiplied(by: aa.adding(e.multiplied(bySmall: 121_665)))
  }
  FieldElement.conditionalSwap(&x2, &x3, bit: swap)
  FieldElement.conditionalSwap(&z2, &z3, bit: swap)

  var inverse = z2.inverted()
  var result = x2.multiplied(by: inverse)
  let output = result.bytes

  zeroize(&k)
  zeroize(&swap)
  zeroize(&bit)
  zeroize(&x2)
  zeroize(&z2)
  zeroize(&x3)
  zeroize(&z3)
  zeroize(&a)
  zeroize(&aa)
  zeroize(&b)
  zeroize(&bb)
  zeroize(&e)
  zeroize(&c)
  zeroize(&d)
  zeroize(&da)
  zeroize(&cb)
  zeroize(&inverse)
  zeroize(&result)
  return output
}

/// Whether all 32 bytes are zero. Every byte is ORed into one value, and only
/// that value is compared, so the time is the same for every input.
func isAllZero(_ bytes: InlineArray<32, UInt8>) -> Bool {
  var accumulated: UInt8 = 0
  for index in 0 ..< 32 {
    accumulated |= bytes[index]
  }
  return accumulated == 0
}

/// The u-coordinate of the base point, 9.
let basePoint = InlineArray<32, UInt8> { $0 == 0 ? 9 : 0 }

/// RFC 7748, section 5: the three low bits and the top bit cleared, and bit
/// 254 set. It works in place, so the clamped scalar lives in one variable.
private func clamp(_ k: inout InlineArray<32, UInt8>) {
  k[0] &= 248
  k[31] &= 127
  k[31] |= 64
}
