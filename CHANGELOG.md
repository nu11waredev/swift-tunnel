# Changelog

## Unreleased

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
