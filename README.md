# Veil

Veil is a Swift implementation of the WireGuard protocol. It does no I/O: it is handed bytes and returns bytes.

## Status

Early. Today the package contains BLAKE2s and HMAC-BLAKE2s and nothing else. It is not ready to protect anything, and it has had no audit.

## Usage

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

The tests check the RFC 7693 vectors, the known-answer vectors from the BLAKE2 reference repository, and fixtures made with Python's hashlib and hmac. `Tests/BLAKE2sTests/Fixtures/generate.py` writes those fixtures and needs only the standard library.

## Requirements

Swift 6.2, and macOS, iOS, tvOS, watchOS and visionOS 26. Linux is untested.

## Licence

MPL 2.0, in LICENSE.

Veil is not affiliated with the WireGuard project. "WireGuard" is a registered trademark of Jason A. Donenfeld.
