#!/bin/zsh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Builds, tests and lints the package. The pre-push hook runs this.
set -euo pipefail

cd "${0:A:h:h}"

swift build
swift test

if command -v swiftformat >/dev/null 2>&1; then
  swiftformat --lint .
else
  print 'swiftformat is not installed, skipping the lint.'
fi
