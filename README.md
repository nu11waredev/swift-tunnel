# Veil

[![CI](https://img.shields.io/github/actions/workflow/status/nu11waredev/swift-veil/ci.yml?branch=main&label=CI)](https://github.com/nu11waredev/swift-veil/actions/workflows/ci.yml)
[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-0969DA)](Package.swift)
[![Licence MPL 2.0](https://img.shields.io/badge/Licence-MPL%202.0-8250DF)](LICENSE)

Veil is a Swift implementation of the WireGuard protocol, built in the open one part at a time. The finished library is the handshake, the key schedule and the packet encryption that a VPN or a security app is built on.

Veil is handed bytes and returns bytes. The app around it owns the sockets and the network interface, so the same code suits an iOS network extension, a Mac app and a Linux server.

## What is being built

Each part is tested against published vectors.

| Part | State |
| --- | --- |
| BLAKE2s and HMAC-BLAKE2s | In the package |
| Key derivation | Next |
| Handshake messages | Planned |
| Noise handshake | Planned |
| Transport encryption | Planned |
| Timers and rekeying | Planned |
| Peers and routing | Planned |
| Cookies | Planned |
| Tunnel state | Planned |

`CHANGELOG.md` records each part as it lands.

## Usage

Hashing, keyed hashing and HMAC-BLAKE2s:

```swift
import BLAKE2s

let message = Array("hello".utf8)
let key = Array("0123456789abcdef0123456789abcdef".utf8)

let digest = BLAKE2s<32>.hash(message.span.bytes)

var hasher = try KeyedBLAKE2s<32>(key: key.span.bytes)
hasher.update(message.span.bytes)
let tag = hasher.finalize()

let code = HMACBLAKE2s.authenticationCode(for: message.span.bytes, key: key.span.bytes)
```

## Tests

Run them with `swift test`. The tests check the RFC 7693 vectors, the known-answer vectors from the BLAKE2 reference repository, and fixtures checked against Python's hashlib and hmac. `Tests/BLAKE2sTests/Fixtures/generate.py` writes those fixtures and needs only the standard library.

Every pull request runs the tests on macOS and on Linux.

## Requirements

Swift 6.4 on Linux, or on macOS, iOS, tvOS, watchOS or visionOS 26.

## Notes

### Scope

Veil takes a packet or a handshake message and returns the bytes to send or deliver. Sockets, the network interface and configuration belong to the app that uses it.

### Specification

Every part is written from the specification: the WireGuard paper and the RFCs for its primitives. Interoperability with other WireGuard implementations is tested as the handshake and transport land.

### Secrets

Keyed hashing and HMAC wipe their keys and working state after use.

### Reporting a vulnerability

`SECURITY.md` has the private channel.

### Contributing

`CONTRIBUTING.md` covers building, testing and what a change needs.

### Name

"WireGuard" is a registered trademark of Jason A. Donenfeld.

## Licence

MPL 2.0, in `LICENSE`.
