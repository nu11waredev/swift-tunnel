// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#elseif canImport(Musl)
  import Musl
#endif

/// Overwrites a value's bytes with zeros in a way the optimizer keeps.
func zeroize(_ value: inout some BitwiseCopyable) {
  withUnsafeMutableBytes(of: &value) { bytes in
    // An empty value has no address and nothing to wipe.
    guard let base = bytes.baseAddress else { return }
    #if canImport(Darwin)
      _ = memset_s(base, bytes.count, 0, bytes.count)
    #else
      explicit_bzero(base, bytes.count)
    #endif
  }
}
