# Changelog

## Unreleased

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
