// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#include "CDataIndependentTiming.h"

// The functions of <timingsafe.h> exist from macOS 15.2, iOS 18.2, tvOS 18.2, watchOS 11.2 and
// visionOS 2.2, and the platforms in Package.swift start above those versions.
#if defined(__APPLE__) && __has_include(<timingsafe.h>)
#include <timingsafe.h>

uint64_t data_independent_timing_enable(void) {
  return timingsafe_enable_if_supported();
}

void data_independent_timing_restore(uint64_t token) {
  timingsafe_restore_if_supported(token);
}
#else
// A platform with no data-independent timing mode that this package can turn on.
uint64_t data_independent_timing_enable(void) {
  return 0;
}

void data_independent_timing_restore(uint64_t token) {
  (void)token;
}
#endif
