// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Testing

/// The statistics are checked against values worked out by hand, so a wrong formula cannot agree
/// with itself. These tests run on every `swift test`; only the measurement is opt-in.
struct StatisticsTests {
  private func moments(_ values: [Double]) -> RunningMoments {
    var moments = RunningMoments()
    for value in values {
      moments.add(value)
    }
    return moments
  }

  @Test func `the mean and sample variance of 1 to 5`() {
    let moments = moments([1, 2, 3, 4, 5])
    #expect(moments.count == 5)
    #expect(moments.mean == 3)
    #expect(moments.variance == 2.5)
  }

  @Test func `the variance of fewer than two values is zero`() {
    #expect(moments([]).variance == 0)
    #expect(moments([7]).variance == 0)
  }

  @Test func `large offsets cost no precision`() {
    // Naive sums of squares of values near 1e9 lose the variance of 2.5 entirely.
    let moments = moments([1, 2, 3, 4, 5].map { $0 + 1e9 })
    #expect(moments.mean == 1e9 + 3)
    #expect(moments.variance == 2.5)
  }

  @Test func `Welch's statistic of 1 to 5 against 2 to 10 in steps of 2`() {
    // Means 3 and 6, variances 2.5 and 10, five values each:
    // (3 - 6) / sqrt(2.5 / 5 + 10 / 5) = -3 / sqrt(2.5).
    let t = welchStatistic(moments([1, 2, 3, 4, 5]), moments([2, 4, 6, 8, 10]))
    #expect(abs(t - -1.8973665961010275) < 1e-12)
  }

  @Test func `Welch's statistic changes sign when the classes swap`() {
    let a = moments([1, 2, 3, 4, 5])
    let b = moments([2, 4, 6, 8, 10])
    #expect(welchStatistic(a, b) == -welchStatistic(b, a))
  }

  @Test func `Welch's statistic weighs each class by its own count and variance`() {
    // Means 10 and 12, variances 4 and 1, counts 4 and 9:
    // (10 - 12) / sqrt(4 / 4 + 1 / 9) = -2 / sqrt(10 / 9).
    let a = moments([8, 9, 11, 12])
    let b = moments([11, 11.5, 12, 12.5, 13, 11, 11.5, 12.5, 13])
    #expect(a.mean == 10)
    #expect(abs(a.variance - 10.0 / 3.0) < 1e-12)
    #expect(b.mean == 12)
    let expected = -2 / (a.variance / 4 + b.variance / 9).squareRoot()
    #expect(abs(welchStatistic(a, b) - expected) < 1e-12)
  }

  @Test func `identical classes give zero`() {
    let a = moments([3, 1, 4, 1, 5, 9, 2, 6])
    #expect(welchStatistic(a, a) == 0)
  }

  @Test func `classes with no spread are zero when equal and infinite when they differ`() {
    #expect(welchStatistic(moments([5, 5, 5]), moments([5, 5])) == 0)
    #expect(welchStatistic(moments([6, 6, 6]), moments([5, 5])) == .infinity)
    #expect(welchStatistic(moments([5, 5, 5]), moments([6, 6])) == -.infinity)
  }

  @Test func `an empty class gives zero`() {
    #expect(welchStatistic(RunningMoments(), moments([1, 2, 3])) == 0)
  }

  @Test(arguments: [
    (0.5, 5.0),
    (0.75, 8.0),
    (0.9, 9.0),
    (1.0, 10.0),
    (0.0, 1.0),
    (0.1, 1.0),
    (0.11, 2.0),
  ])
  func `the nearest-rank quantile of 1 to 10`(fraction: Double, expected: Double) {
    #expect(quantile(of: (1 ... 10).map(Double.init), fraction: fraction) == expected)
  }

  @Test func `a small difference is found once the long tail is cut`() {
    // The fixed class runs 5 ns slower than the random class. Both classes have the same
    // spread, and one call in a hundred in each is 100 microseconds long, as when an interrupt
    // lands in it.
    var timings = Timings()
    var generator = SplitMix64(seed: 1)
    for _ in 0 ..< 20000 {
      for isFixed in [true, false] {
        let noise = Double(generator.next() % 20)
        let interrupted = generator.next() % 100 == 0
        timings.append(
          nanoseconds: 1000 + noise + (isFixed ? 5 : 0) + (interrupted ? 100_000 : 0),
          isFixed: isFixed,
        )
      }
    }
    let cuts = statistics(of: timings)
    #expect(cuts.count == cutFractions.count + 1)
    #expect(cuts.first?.label == "all calls")
    // The long calls hide the difference in the uncropped timings, and cutting them shows it.
    #expect(abs(cuts[0].statistic) < 4.5)
    #expect(largestAbsoluteStatistic(cuts) > 20)
  }

  @Test func `the same distribution in both classes stays under the threshold`() {
    var timings = Timings()
    var generator = SplitMix64(seed: 2)
    for _ in 0 ..< 40000 {
      timings.append(
        nanoseconds: 1000 + Double(generator.next() % 20),
        isFixed: generator.next() % 2 == 0,
      )
    }
    #expect(largestAbsoluteStatistic(statistics(of: timings)) < 4.5)
  }

  @Test func `a cut keeps the calls at or below the quantile of both classes pooled`() {
    var timings = Timings()
    for value in 1 ... 100 {
      timings.append(nanoseconds: Double(value), isFixed: value.isMultiple(of: 2))
    }
    let cuts = statistics(of: timings)
    // The 50th percentile of 1 to 100 is 50, so 25 even and 25 odd values stay.
    #expect(cuts[1].fixedCount == 25)
    #expect(cuts[1].randomCount == 25)
    #expect(cuts[0].fixedCount == 50)
    #expect(cuts[0].randomCount == 50)
  }
}

/// A small deterministic generator, so the synthetic timings of these tests are the same on every
/// run.
struct SplitMix64: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}
