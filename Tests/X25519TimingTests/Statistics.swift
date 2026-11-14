// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// The count, mean and sum of squared deviations of the values added so far, kept by the online
/// update of Welford. Each value adjusts the running mean and the running sum, so no list of
/// values is held and a large offset, such as timings in nanoseconds, costs no precision.
struct RunningMoments {
  private(set) var count = 0
  private(set) var mean = 0.0
  private var sumOfSquares = 0.0

  mutating func add(_ value: Double) {
    count += 1
    let delta = value - mean
    mean += delta / Double(count)
    sumOfSquares += delta * (value - mean)
  }

  /// The sample variance, with the divisor `count - 1`. It is zero for fewer than two values.
  var variance: Double {
    count > 1 ? sumOfSquares / Double(count - 1) : 0
  }
}

/// Welch's t-statistic for the difference of two means whose variances may differ:
/// `(mean a - mean b) / sqrt(variance a / count a + variance b / count b)`.
///
/// When both variances are zero the statistic is zero for equal means and infinite, with the sign
/// of the difference, for different means. A class with no values gives zero.
func welchStatistic(_ a: RunningMoments, _ b: RunningMoments) -> Double {
  guard a.count > 0, b.count > 0 else { return 0 }
  let spread = a.variance / Double(a.count) + b.variance / Double(b.count)
  let difference = a.mean - b.mean
  if spread == 0 {
    return difference == 0 ? 0 : (difference > 0 ? .infinity : -.infinity)
  }
  return difference / spread.squareRoot()
}

/// The value at `fraction` of an ascending list, by the nearest rank: the smallest value that at
/// least that fraction of the list does not exceed.
func quantile(of sorted: [Double], fraction: Double) -> Double {
  precondition(!sorted.isEmpty, "A quantile needs at least one value")
  let rank = Int((fraction * Double(sorted.count)).rounded(.up))
  return sorted[min(max(rank, 1), sorted.count) - 1]
}

/// The timings of one run: one per call, with the class of the input that call took.
struct Timings {
  /// The duration of each call, in nanoseconds.
  var nanoseconds: [Double] = []
  /// Whether the call at the same index took the fixed input.
  var isFixed: [Bool] = []

  mutating func append(nanoseconds: Double, isFixed: Bool) {
    self.nanoseconds.append(nanoseconds)
    self.isFixed.append(isFixed)
  }
}

/// The statistic of one cut of the timings.
struct CutStatistic {
  /// `all calls`, or the percentile of the pooled timings at or below which a call is kept.
  var label: String
  var fixedCount: Int
  var randomCount: Int
  /// Welch's t-statistic of the fixed class against the random class.
  var statistic: Double
}

/// The fractions of the pooled timings at which the long upper tail is cut off. A timing
/// distribution has a long tail from interrupts and cache misses, which can swamp a small
/// difference in the bulk, so the statistic is also computed on the timings that stay at or below
/// each of these fractions.
let cutFractions = [0.5, 0.75, 0.9, 0.95, 0.99]

/// Welch's t-statistic of the fixed class against the random class, once on every timing and once
/// for each cut of the long tail. A cut lies at a quantile of the timings of both classes pooled,
/// so it favors neither class.
func statistics(of timings: Timings) -> [CutStatistic] {
  let sorted = timings.nanoseconds.sorted()
  var cuts: [(label: String, limit: Double)] = [("all calls", .infinity)]
  for fraction in cutFractions {
    let percentile = Int((fraction * 100).rounded())
    cuts.append(
      ("calls up to the \(percentile)th percentile", quantile(of: sorted, fraction: fraction)),
    )
  }
  return cuts.map { cut in
    var fixed = RunningMoments()
    var random = RunningMoments()
    for index in timings.nanoseconds.indices where timings.nanoseconds[index] <= cut.limit {
      if timings.isFixed[index] {
        fixed.add(timings.nanoseconds[index])
      } else {
        random.add(timings.nanoseconds[index])
      }
    }
    return CutStatistic(
      label: cut.label,
      fixedCount: fixed.count,
      randomCount: random.count,
      statistic: welchStatistic(fixed, random),
    )
  }
}

/// The largest absolute statistic of the cuts, which the threshold is compared with.
func largestAbsoluteStatistic(_ cuts: [CutStatistic]) -> Double {
  cuts.map { abs($0.statistic) }.max() ?? 0
}
