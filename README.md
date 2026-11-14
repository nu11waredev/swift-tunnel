# Tunnel

[![CI](https://img.shields.io/github/actions/workflow/status/nu11waredev/swift-tunnel/ci.yml?branch=main&label=CI)](https://github.com/nu11waredev/swift-tunnel/actions/workflows/ci.yml)
[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-0969DA)](Package.swift)
[![License MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-8250DF)](LICENSE)

Tunnel is an implementation of the WireGuard protocol, written in Swift.

- [Learn more](#learn-more)
- [Basic usage](#basic-usage)
- [Installation](#installation)
- [Community](#community)
- [License](#license)

## Learn more

Today the package contains the BLAKE2s and X25519 library products, and a `Tunnel` module with key derivation and the handshake message formats. The `Tunnel` module becomes a library product with the Noise handshake, planned for 2026-11-27. Tunnel state, planned for 2027-01-15, takes bytes and the current time as input and returns bytes as output. Every test runs without a network. The two products are separate, so an app imports only the one it uses.

The code uses current Swift. Input is a `RawSpan` and output is a `Span`. Fixed-size state is an `InlineArray`, and digest lengths are integer generic parameters. Every function that throws uses typed throws. The keyed hasher and the X25519 secrets are noncopyable types.

Every part is written from the specification: the [WireGuard paper](https://www.wireguard.com/papers/wireguard.pdf) and the RFCs for its primitives, [RFC 7693](https://www.rfc-editor.org/rfc/rfc7693) for BLAKE2, [RFC 2104](https://www.rfc-editor.org/rfc/rfc2104) for HMAC and [RFC 7748](https://www.rfc-editor.org/rfc/rfc7748) for X25519.

[`ROADMAP.md`](ROADMAP.md) lists each part of the package and its state.

## Basic usage

Hash a message, hash it with a key, and compute HMAC-BLAKE2s:

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

| Type | Description |
| --- | --- |
| `BLAKE2s<N>` | `BLAKE2s<N>` is a hash of `N` bytes, from 1 to 32. The static function `hash` takes a whole message. A hasher made with `init()` takes a message in pieces through `update`, and `finalize` returns the digest. |
| `KeyedBLAKE2s<N>` | `KeyedBLAKE2s<N>` is a hash of `N` bytes with a key of 1 to 32 bytes. The initializer throws `BLAKE2KeyError` for a key of any other length. |
| `HMACBLAKE2s` | `HMACBLAKE2s` computes HMAC over BLAKE2s-256. The key can have any length. |
| `BLAKE2Digest<N>` | `BLAKE2Digest<N>` is the result of a hash. `span` gives its bytes, and `==` compares every byte. |

Two sides agree on a shared secret with X25519:

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

| Type | Description |
| --- | --- |
| `X25519PrivateKey` | `X25519PrivateKey` is a private key, made from 32 random bytes or from 32 bytes given by the caller. `publicKey` derives the public key, and `sharedSecret(with:)` agrees a secret with a peer. |
| `X25519PublicKey` | `X25519PublicKey` is a public key of 32 bytes, read from a peer or derived from a private key. `span` gives its bytes. |
| `X25519SharedSecret` | `X25519SharedSecret` is the 32 bytes that both sides agree on. `span` gives them. |
| `X25519KeyError` | `X25519KeyError` is thrown when a key is read from bytes that are not 32 bytes long. |
| `X25519SharedSecretError` | `X25519SharedSecretError` is thrown when the secret comes out all zero, which happens when the peer's key is a point of small order. |

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/nu11waredev/swift-tunnel", branch: "main"),
],
```

Then add the products to a target:

```swift
.target(
  name: "App",
  dependencies: [
    .product(name: "BLAKE2s", package: "swift-tunnel"),
    .product(name: "X25519", package: "swift-tunnel"),
  ],
),
```

In Xcode, choose File > Add Package Dependencies, then enter the repository URL.

Tunnel requires Swift 6.4, with Xcode 27 on Apple platforms. It runs on macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26 and Linux.

## Community

For casual chat about the project, join the [Discord server](https://discord.gg/d8KgvpAKcv). Report a bug or ask a question in the repository's [issues](https://github.com/nu11waredev/swift-tunnel/issues). Report a vulnerability privately from the repository's Security tab. [`SECURITY.md`](SECURITY.md) has the details.

## License

Tunnel is available under the Mozilla Public License 2.0. See [`LICENSE`](LICENSE).

"WireGuard" is a registered trademark of Jason A. Donenfeld.
