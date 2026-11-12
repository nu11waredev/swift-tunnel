# Tunneling

[![CI](https://img.shields.io/github/actions/workflow/status/nu11waredev/swift-tunneling/ci.yml?branch=main&label=CI)](https://github.com/nu11waredev/swift-tunneling/actions/workflows/ci.yml)
[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-0969DA)](Package.swift)
[![Licence MPL 2.0](https://img.shields.io/badge/Licence-MPL%202.0-8250DF)](LICENSE)

Tunneling is a Swift package for the parts a VPN or a security app is built on. Its centre is an implementation of the WireGuard protocol. The finished library covers the handshake, the key schedule and the packet encryption, with DNS filtering for ads and trackers inside the tunnel.

## Design

The tunnel is designed to be handed bytes and the time, and to return bytes. The app around it owns the sockets, the network interface and the clock. The same code suits an iOS network extension, a Mac app and a Linux server, and every test runs without a network.

Each part is its own module, so an app imports only what it uses. The package has no dependencies.

The code uses current Swift: `RawSpan` for input and `Span` for output, `InlineArray` for fixed-size state, integer generic parameters for digest lengths, typed throws, and noncopyable types for the keyed hasher and the X25519 secrets.

## What is being built

Each part is tested against published vectors and recorded in `CHANGELOG.md` as it lands.

| Part | What it does | State |
| --- | --- | --- |
| BLAKE2s and HMAC-BLAKE2s | The hash and the message authentication code the protocol uses throughout | In the package |
| X25519 | The Diffie-Hellman function behind every key agreement in the handshake | In the package |
| Key derivation | Turns handshake secrets into chaining keys and session keys | In the package |
| Handshake messages | Encodes and decodes the initiation, the response, the cookie reply and the transport data header | In the package |
| Noise handshake | The exchange that authenticates two peers and agrees their session keys | Next |
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
  .package(url: "https://github.com/nu11waredev/swift-tunneling", from: "0.1.0"),
],
```

Then add the module to a target:

```swift
.target(
  name: "App",
  dependencies: [
    .product(name: "BLAKE2s", package: "swift-tunneling"),
    .product(name: "X25519", package: "swift-tunneling"),
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

Key agreement with X25519:

```swift
import X25519

let alice = X25519PrivateKey()
let bob = X25519PrivateKey()

// Each side sends the 32 bytes of its public key to the other.
let fromAlice = try X25519PublicKey(alice.publicKey.span.bytes)
let fromBob = try X25519PublicKey(bob.publicKey.span.bytes)

let aliceSecret = try alice.sharedSecret(with: fromBob)
let bobSecret = try bob.sharedSecret(with: fromAlice)
```

| Type | Use |
| --- | --- |
| `X25519PrivateKey` | 32 random bytes, or 32 bytes given. `publicKey` derives the public key, and `sharedSecret(with:)` agrees a secret with a peer. |
| `X25519PublicKey` | 32 bytes, read from a peer or derived from a private key. `span` gives its bytes. |
| `X25519SharedSecret` | The agreed 32 bytes. `span` gives them. |
| `X25519KeyError` | Thrown when a key is read from bytes that are not 32 bytes long. |
| `X25519SharedSecretError` | Thrown when the secret comes out all zero, because the peer's key is a point of small order. |

## Security

Keyed hashing and HMAC wipe their keys and working state after use. A keyed hasher cannot be copied, so its key exists in one place and is wiped when the hasher ends.

Comparing two digests reads every byte, even after a difference is found.

X25519 private keys and shared secrets cannot be copied, and their bytes are wiped when they end. The ladder runs the same field operations in the same order for every private key and every public key, swaps values by masking, and wipes its working values before it returns. A shared secret that comes out all zero throws `X25519SharedSecretError.allZero`. The check ORs every byte before it looks at the result.

A vulnerability is reported privately from the repository's Security tab. `SECURITY.md` has the details.

## Tests

Run them with `swift test`. The tests check the RFC 7693 vectors, the known-answer vectors from the BLAKE2 reference repository, and fixtures checked against Python's hashlib and hmac. `Tests/BLAKE2sTests/Fixtures/generate.py` writes those fixtures and needs only the standard library. The message formats are checked against messages that `Tests/TunnelingTests/Fixtures/generate_messages.py` packs with Python's struct module from the paper's field tables. X25519 is checked against the RFC 7748 vectors, the points of small order listed at [cr.yp.to/ecdh.html](https://cr.yp.to/ecdh.html), and fixtures that `Tests/X25519Tests/Fixtures/generate.py` computes from the RFC's formulas with Python's integers. The million-round iterated vector runs when `TUNNELING_LONG_TESTS` is set. The usage examples above are compiled and checked by tests.

Every pull request runs the tests on macOS and on Linux.

## Requirements

Swift 6.4 on Linux, or on macOS, iOS, tvOS, watchOS or visionOS 26.

## Notes

### Specification

Every part is written from the specification: the [WireGuard paper](https://www.wireguard.com/papers/wireguard.pdf) and the RFCs for its primitives, [RFC 7693](https://www.rfc-editor.org/rfc/rfc7693) for BLAKE2, [RFC 2104](https://www.rfc-editor.org/rfc/rfc2104) for HMAC and [RFC 7748](https://www.rfc-editor.org/rfc/rfc7748) for X25519. Interoperability with other WireGuard implementations is tested as the handshake and transport land.

### Contributing

Issues and pull requests are welcome. `CONTRIBUTING.md` covers building, testing and what a change needs.

### Name

"WireGuard" is a registered trademark of Jason A. Donenfeld.

## Licence

MPL 2.0, in `LICENSE`.
