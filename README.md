# Tunnel

[![CI](https://img.shields.io/github/actions/workflow/status/nu11waredev/swift-tunnel/ci.yml?branch=main&label=CI)](https://github.com/nu11waredev/swift-tunnel/actions/workflows/ci.yml)
[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-0969DA)](Package.swift)
[![Licence MPL 2.0](https://img.shields.io/badge/Licence-MPL%202.0-8250DF)](LICENSE)

Tunnel is an implementation of the WireGuard protocol, written in Swift. The finished library covers the handshake, key derivation, packet encryption, timers and rekeying, routing of packets between peers, and DNS filtering for ads and trackers inside the tunnel. Today the package contains BLAKE2s and HMAC-BLAKE2s, X25519, key derivation and the handshake message formats.

## Design

The tunnel takes bytes and the current time as input and returns bytes as output. The app that uses it owns the sockets, the network interface and the clock. The same code suits an iOS network extension, a Mac app and a Linux server. Every test runs without a network. Each part is its own module, so an app imports only the parts it uses.

The code uses current Swift. Input is a `RawSpan` and output is a `Span`. Fixed-size state is an `InlineArray`, and digest lengths are integer generic parameters. Every function that throws uses typed throws. The keyed hasher and the X25519 secrets are noncopyable types.

Every part is written from the specification: the [WireGuard paper](https://www.wireguard.com/papers/wireguard.pdf) and the RFCs for its primitives, [RFC 7693](https://www.rfc-editor.org/rfc/rfc7693) for BLAKE2, [RFC 2104](https://www.rfc-editor.org/rfc/rfc2104) for HMAC and [RFC 7748](https://www.rfc-editor.org/rfc/rfc7748) for X25519.

## What is being built

Each part is tested against published vectors and recorded in `CHANGELOG.md` when it is added to the package.

| Part | Description | State |
| --- | --- | --- |
| BLAKE2s and HMAC-BLAKE2s | BLAKE2s and HMAC-BLAKE2s compute the hash and the message authentication code that the protocol uses throughout. | In the package |
| X25519 | X25519 computes the Diffie-Hellman function behind every key agreement in the handshake. | In the package |
| Key derivation | Key derivation turns handshake secrets into chaining keys and session keys. | In the package |
| Handshake messages | The handshake messages encode and decode the initiation, the response, the cookie reply and the transport data header. | In the package |
| Noise handshake | The Noise handshake authenticates two peers and agrees their session keys. | Next |
| Transport encryption | Transport encryption encrypts packets and uses counters to reject packets that are replayed. | Planned |
| Timers and rekeying | Timers and rekeying send keepalives, retry handshakes and rotate keys, using the time the app passes in. | Planned |
| Peers and routing | Peers and routing map each peer's allowed addresses to its session. | Planned |
| Cookies | Cookies let a server under load answer a handshake message with a cookie reply instead of processing it. | Planned |
| Tunnel state | Tunnel state joins the other parts into one tunnel that takes bytes and the current time and returns bytes. | Planned |
| DNS filtering | DNS filtering applies blocklists for ads and trackers to DNS queries inside the tunnel. | Planned |

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/nu11waredev/swift-tunnel", from: "0.1.0"),
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

## Usage

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
| `X25519PrivateKey` | `X25519PrivateKey` is a private key, made from 32 random bytes or from 32 bytes you provide. `publicKey` derives the public key, and `sharedSecret(with:)` agrees a secret with a peer. |
| `X25519PublicKey` | `X25519PublicKey` is a public key of 32 bytes, read from a peer or derived from a private key. `span` gives its bytes. |
| `X25519SharedSecret` | `X25519SharedSecret` is the 32 bytes that both sides agree on. `span` gives them. |
| `X25519KeyError` | `X25519KeyError` is thrown when a key is read from bytes that are not 32 bytes long. |
| `X25519SharedSecretError` | `X25519SharedSecretError` is thrown when the secret comes out all zero, which happens when the peer's key is a point of small order. |

## Security

Keyed hashing and HMAC wipe their keys and working state after use. A keyed hasher is a noncopyable type, so its key exists in one place. The key and the state are wiped when `finalize()` returns, or when the hasher goes out of scope without being finalized.

Comparing two digests reads every byte, even after a difference is found.

X25519 private keys and shared secrets are noncopyable types, and their bytes are wiped when the value goes out of scope. The X25519 ladder runs the same field operations in the same order for every private key and every public key, swaps values by masking, and wipes its working values before it returns. A shared secret that comes out all zero throws `X25519SharedSecretError.allZero`. The check combines every byte with OR before it looks at the result.

Report a vulnerability privately from the repository's Security tab. `SECURITY.md` has the details.

## Tests

Run the tests with `swift test`.

The BLAKE2s tests check the RFC 7693 vectors, the known-answer vectors from the BLAKE2 reference repository, and fixtures checked against Python's `hashlib` and `hmac`. `Tests/BLAKE2sTests/Fixtures/generate.py` writes those fixtures.

The message format tests check against fixtures that `Tests/TunnelTests/Fixtures/generate_messages.py` builds from the paper's field tables with Python's `struct` module.

The X25519 tests check the RFC 7748 vectors, the points of small order listed at [cr.yp.to/ecdh.html](https://cr.yp.to/ecdh.html), and fixtures that `Tests/X25519Tests/Fixtures/generate.py` computes from the RFC's formulas with Python's integers. The million-round iterated vector runs when `TUNNEL_LONG_TESTS` is set.

Tests compile and check the usage examples above. CI runs the tests on macOS and Linux for every pull request.

## Requirements

Tunnel requires Swift 6.4, with Xcode 27 on Apple platforms. It runs on macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26 and Linux.

## Licence

Tunnel is available under the Mozilla Public License 2.0. See `LICENSE`.

"WireGuard" is a registered trademark of Jason A. Donenfeld.
