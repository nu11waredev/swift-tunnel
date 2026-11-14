# Changelog

## Unreleased

- Turned on the processor's data-independent timing mode for every X25519 call, through a new C target, `CDataIndependentTiming`, that calls `timingsafe_enable_if_supported` on Apple platforms and does nothing elsewhere. With the mode off, an Apple M4 took about 5 ns less on a scalar of all zeros or all 0xFF than on a random scalar, and the timing test's statistic was above 10. The timing test now runs the scalars of all zeros and all 0xFF as fixed classes, besides the private key of RFC 7748, section 6.1, and the README's Security section names the three.
- Added a timing test for X25519 that compares a fixed private key with random ones, and fails when Welch's t-statistic is above 4.5. `scripts/timing` runs it in a release build and prints the statistic. It is left out of `scripts/check`, and the README's Security section says what it measures.
- Ran the tests under the address, thread and undefined behavior sanitizers in `scripts/check`, each in its own build directory under `.build`. A report from any of them fails the check, and CI runs the same script.
- Added the X25519 test vectors of Project Wycheproof: 518 vectors, 264 valid and 254 acceptable, with the points of small order and the non-canonical public keys among them. The library returns the listed shared secret for every vector except the 31 whose secret is all zero, for which it throws `allZero`.
- Documented every public symbol in BLAKE2s and X25519 that had no documentation comment, with what it throws or traps on where it can.
- Corrected the X25519 documentation to list the values the ladder zeroizes, and zeroized the powers that the field inversion names.
- Linked the Discord server from the README's Community section.
- Turned every compiler warning into an error in each target. The setting flagged one unused result in the X25519 tests, which the test now discards explicitly.
- Dated the planned parts in `ROADMAP.md`, and named in the README the products and modules that the package holds today.
- Reordered the README into a definition, Learn more, Basic usage, Installation, Community and License. The table of parts moved to `ROADMAP.md`, and the test notes and the notes on what the code protects moved to `CONTRIBUTING.md`.
- Spelled License in American English, and changed the commit form in `CONTRIBUTING.md` to a sentence with no type prefix.
- CI can be started by hand from the Actions page, as well as by a push to `main` or a pull request.
- Renamed `scripts/ci.sh` to `scripts/check`. The pre-push hook and CI run it, and `CONTRIBUTING.md` gives the commit form.
- Renamed the package from `swift-tunneling` to `swift-tunnel` and the module from `Tunneling` to `Tunnel`.
- Renamed the environment variable for the long X25519 test from `TUNNELING_LONG_TESTS` to `TUNNEL_LONG_TESTS`.
- Added the handshake message formats.
- Added X25519.

## 0.1.0 - 2026-11-12

- BLAKE2s, unkeyed and keyed, and HMAC-BLAKE2s.
- Linux support.
- Swift 6.4.
- Key derivation.
