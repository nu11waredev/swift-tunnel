// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#ifndef CDATAINDEPENDENTTIMING_H
#define CDATAINDEPENDENTTIMING_H

#include <stdint.h>

/// Turns on the processor's data-independent timing mode for the calling thread, on a platform and
/// a processor that have it, and returns a token for `data_independent_timing_restore`. Where the
/// mode does not exist the call does nothing and returns 0.
///
/// On Apple platforms this calls `timingsafe_enable_if_supported`, which turns on PSTATE.DIT with
/// the speculation barrier the processor needs, and which does nothing on a processor without DIT.
uint64_t data_independent_timing_enable(void);

/// Puts the mode back as it was before the `data_independent_timing_enable` call that returned
/// `token`. If the mode was on before that call, it stays on.
void data_independent_timing_restore(uint64_t token);

#endif
