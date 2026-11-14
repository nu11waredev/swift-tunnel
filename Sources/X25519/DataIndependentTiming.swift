// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

internal import CDataIndependentTiming

/// Runs `body` with the processor's data-independent timing mode (DIT) on, and returns what it
/// returns.
///
/// With the mode off, an Apple silicon processor may take a different time for an instruction
/// depending on the values it works on. With it on, those instructions take their worst-case time
/// whatever the values. The mode belongs to the calling thread, and `body` runs to its end on that
/// thread. Turning the mode on includes the speculation barrier that Apple's documentation asks
/// for, and when `body` returns the mode is put back as it was before the call. Where the platform
/// or the processor has no such mode, the call only runs `body`.
func withDataIndependentTiming<Result>(_ body: () -> Result) -> Result {
  let token = data_independent_timing_enable()
  defer { data_independent_timing_restore(token) }
  return body()
}
