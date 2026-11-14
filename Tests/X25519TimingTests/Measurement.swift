// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Dispatch
import X25519

/// Times `operation` on a fixed scalar and on random scalars, with the class of each call chosen
/// by a coin flip, and returns every timing.
///
/// The scalars are all made before the first call, and the coin flips with them, so the timed
/// region holds nothing but the call. The classes are interleaved in random order, so a slow
/// drift of the machine, such as a change of clock frequency or a busy neighbor, falls on both
/// classes alike. The first `warmUp` calls are discarded.
///
/// - Parameters:
///   - count: The number of timed calls.
///   - warmUp: The number of calls made and discarded first, to fill caches and settle the clock.
///   - fixed: The scalar of the fixed class.
///   - operation: The call to time. It is given a key made from the scalar of the class.
func measure(
  count: Int,
  warmUp: Int = 1000,
  fixed: InlineArray<32, UInt8>,
  operation: (borrowing X25519PrivateKey) -> UInt8,
) -> Timings {
  var generator = SystemRandomNumberGenerator()
  let total = count + warmUp
  let classes = (0 ..< total).map { _ in Bool.random(using: &generator) }
  let scalars = classes.map { isFixed in
    isFixed ? fixed : InlineArray<32, UInt8> { _ in UInt8.random(in: 0 ... 255, using: &generator) }
  }

  var timings = Timings()
  timings.nanoseconds.reserveCapacity(count)
  timings.isFixed.reserveCapacity(count)
  var sink: UInt8 = 0
  for index in 0 ..< total {
    let key = X25519PrivateKey(bytes: scalars[index])
    let start = DispatchTime.now().uptimeNanoseconds
    sink &+= operation(key)
    let end = DispatchTime.now().uptimeNanoseconds
    if index >= warmUp {
      timings.append(nanoseconds: Double(end - start), isFixed: classes[index])
    }
  }
  // The sum is read here so that no call can be dropped as unused.
  withExtendedLifetime(sink) {}
  return timings
}
