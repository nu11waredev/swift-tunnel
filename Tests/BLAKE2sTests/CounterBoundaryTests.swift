// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

@testable import BLAKE2s
import Testing

/// RFC 7693, section 3.2, splits the byte counter into two 32-bit words, t0 and t1.
/// These tests start the counter just below 2^32 and hash on across it.
///
/// Python's hashlib cannot start a hash at such a counter, so the expected digests
/// come from a model of RFC 7693 in `Fixtures/generate.py`, which that script first
/// checks against hashlib wherever hashlib can be asked.
struct CounterBoundaryTests {
  @Test(arguments: FixtureTests.file.counterBoundary)
  func `the carry from t0 into t1 matches the RFC 7693 model`(
    fixture: FixtureTests.CounterBoundaryFixture,
  ) {
    var core = BLAKE2sCore(digestCount: 32)
    core.byteCount = fixture.start
    let input = [UInt8](hex: fixture.input)
    core.update(input.span.bytes)
    let digest = BLAKE2Digest<32>(chain: core.finalize())
    #expect(digest.hex == fixture.output)
  }

  @Test func `fixtures start below 2^32 and end above it`() {
    let fixtures = FixtureTests.file.counterBoundary
    #expect(fixtures
      .contains { $0.start < 1 << 32 && $0.start + UInt64($0.input.count / 2) > 1 << 32 })
    #expect(fixtures.contains { $0.start >= 1 << 32 })
  }
}
