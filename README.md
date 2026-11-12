# Veil

[![CI](https://img.shields.io/github/actions/workflow/status/nu11waredev/swift-veil/ci.yml?branch=main&label=CI)](https://github.com/nu11waredev/swift-veil/actions/workflows/ci.yml)
[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-0969DA)](Package.swift)
[![Licence MPL 2.0](https://img.shields.io/badge/Licence-MPL%202.0-8250DF)](LICENSE)

Veil is a Swift package for the parts a VPN or a security app is built on. Its centre is an implementation of the WireGuard protocol. The finished library covers the handshake, the key schedule and the packet encryption, with DNS filtering for ads and trackers inside the tunnel.

## Design

The tunnel is designed to be handed bytes and the time, and to return bytes. The app around it owns the sockets, the network interface and the clock. The same code suits an iOS network extension, a Mac app and a Linux server, and every test runs without a network.

Each part is its own module, so an app imports only what it uses. The package has no dependencies.

The code uses current Swift: `RawSpan` for input and `Span` for output, `InlineArray` for fixed-size state, integer generic parameters for digest lengths, typed throws, and a noncopyable type for the keyed hasher.

## What is being built

Each part is tested against published vectors and recorded in `CHANGELOG.md` as it lands.

| Part | What it does | State |
| --- | --- | --- |
| BLAKE2s and HMAC-BLAKE2s | The hash and the message authentication code the protocol uses throughout | In the package |
| Key derivation | Turns handshake secrets into chaining keys and session keys | Next |
| Handshake messages | Encodes and decodes the initiation, the response and the cookie reply | Planned |
| Noise handshake | The exchange that authenticates two peers and agrees their session keys | Planned |
| Transport encryption | Packet encryption with counters and replay protection | Planned |
| Timers and rekeying | Keepalives, handshake retries and key rotation, driven by the time the app passes in | Planned |
| Peers and routing | Maps each peer's allowed addresses to its session | Planned |
| Cookies | The reply a busy server sends to keep answering under load | Planned |
| Tunnel state | One `Tunnel` type that ties the parts together | Planned |
| DNS filtering | Blocklists for ads and trackers, applied to DNS queries inside the tunnel | Planned |

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/nu11waredev/swift-veil", from: "0.1.0"),
],
```

Then add the module to a target:

```swift
.target(
  name: "App",
  dependencies: [
    .product(name: "BLAKE2s", package: "swift-veil"),
  ],
),
```

In Xcode, choose File, Add Package Dependencies and enter the repository URL.

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

| Type | Use |
| --- | --- |
| `BLAKE2s<N>` | A hash of `N` bytes, 1 to 32. `hash` takes a whole message. `update` takes it in pieces and `finalize` returns the digest. |
| `KeyedBLAKE2s<N>` | The same with a key of 1 to 32 bytes. A key of another length throws `BLAKE2KeyError`. |
| `HMACBLAKE2s` | HMAC over BLAKE2s-256, with a key of any length. |
| `BLAKE2Digest<N>` | The result. `span` gives its bytes, and `==` compares every byte. |

## Security

Keyed hashing and HMAC wipe their keys and working state after use. A keyed hasher cannot be copied, so its key exists in one place and is wiped when the hasher ends.

Comparing two digests reads every byte, even after a difference is found.

A vulnerability is reported privately from the repository's Security tab. `SECURITY.md` has the details.

## Tests

Run them with `swift test`. The tests check the RFC 7693 vectors, the known-answer vectors from the BLAKE2 reference repository, and fixtures checked against Python's hashlib and hmac. `Tests/BLAKE2sTests/Fixtures/generate.py` writes those fixtures and needs only the standard library. The usage example above is compiled and checked by a test.

Every pull request runs the tests on macOS and on Linux.

## Requirements

Swift 6.4 on Linux, or on macOS, iOS, tvOS, watchOS or visionOS 26.

## Notes

### Specification

Every part is written from the specification: the [WireGuard paper](https://www.wireguard.com/papers/wireguard.pdf) and the RFCs for its primitives, [RFC 7693](https://www.rfc-editor.org/rfc/rfc7693) for BLAKE2 and [RFC 2104](https://www.rfc-editor.org/rfc/rfc2104) for HMAC. Interoperability with other WireGuard implementations is tested as the handshake and transport land.

### Contributing

Issues and pull requests are welcome. `CONTRIBUTING.md` covers building, testing and what a change needs.

### Name

"WireGuard" is a registered trademark of Jason A. Donenfeld.

## Licence

MPL 2.0, in `LICENSE`.
