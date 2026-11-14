// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Testing
import X25519

/// Fixed against random private keys, timed through the public interface. It runs when the
/// environment variable `TUNNEL_TIMING_TESTS` is set, in a release build, and `scripts/timing`
/// does both. The sanitizers and a loaded machine add noise that is larger than the differences
/// this test looks for, so `scripts/check` leaves it out.
struct X25519TimingTests {
  /// The number of timed calls: about half in each class.
  static let sampleCount = 500_000

  /// The threshold on the absolute value of Welch's t-statistic. A value above it is evidence of a
  /// difference in time between the two classes.
  static let threshold = 4.5

  /// The public key of RFC 7748, section 6.1, for Bob: a fixed peer for every call, so the only
  /// input that changes between the classes is the private key.
  static let peer = X25519PublicKey(
    bytes: [
      0xDE, 0x9E, 0xDB, 0x7D, 0x7B, 0x7D, 0xC1, 0xB4, 0xD3, 0x5B, 0x61, 0xC2, 0xEC, 0xE4, 0x35,
      0x37, 0x3F, 0x83, 0x43, 0xC8, 0x5B, 0x78, 0x67, 0x4D, 0xAD, 0xFC, 0x7E, 0x14, 0x6F, 0x88,
      0x2B, 0x4F,
    ],
  )

  /// The private key of RFC 7748, section 6.1, for Alice: the scalar of the fixed class. The
  /// other class takes a new random scalar for every call.
  static let fixedScalar: InlineArray<32, UInt8> = [
    0x77, 0x07, 0x6D, 0x0A, 0x73, 0x18, 0xA5, 0x7D, 0x3C, 0x16, 0xC1, 0x72, 0x51, 0xB2, 0x66,
    0x45, 0xDF, 0x4C, 0x2F, 0x87, 0xEB, 0xC0, 0x99, 0x2A, 0xB1, 0x77, 0xFB, 0xA5, 0x1D, 0xB9,
    0x2C, 0x2A,
  ]

  @Test(.enabled(if: ProcessInfo.processInfo.environment["TUNNEL_TIMING_TESTS"] != nil))
  func `the time of sharedSecret does not depend on the private key`() {
    let peer = Self.peer
    let timings = measure(
      count: Self.sampleCount,
      fixed: Self.fixedScalar,
    ) { key in
      do {
        let secret = try key.sharedSecret(with: peer)
        return secret.span[0]
      } catch {
        return 0
      }
    }
    report(timings, label: "X25519PrivateKey.sharedSecret(with:)")
  }

  /// Prints each cut's statistic and fails when the largest exceeds the threshold.
  private func report(_ timings: Timings, label: String) {
    let cuts = statistics(of: timings)
    let largest = largestAbsoluteStatistic(cuts)
    print("\(label): fixed scalar against random scalars, \(timings.nanoseconds.count) calls")
    for cut in cuts {
      let statistic = String(format: "%8.2f", cut.statistic)
      let counts = "\(cut.fixedCount) fixed, \(cut.randomCount) random"
      print("  t = \(statistic)  \(cut.label) (\(counts))")
    }
    print(String(format: "  largest |t| = %.2f, threshold %.1f", largest, Self.threshold))
    #expect(
      largest < Self.threshold,
      "The largest |t| of \(label) is \(largest), above \(Self.threshold)",
    )
  }
}
