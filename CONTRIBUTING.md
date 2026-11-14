# Contributing

Issues and pull requests are welcome. For anything larger than a fix, open an issue first so the approach can be agreed before the work is done.

## Building and testing

```
swift build
swift test
```

`scripts/check` runs both, then `swiftformat --lint` when SwiftFormat is installed. CI runs the same script on macOS and Linux for every pull request and every push to `main`. `scripts/install-hooks.sh` makes `git push` run it first.

## Tests

The BLAKE2s tests check the RFC 7693 vectors, the known-answer vectors from the BLAKE2 reference repository, and fixtures checked against Python's `hashlib` and `hmac`. `Tests/BLAKE2sTests/Fixtures/generate.py` writes those fixtures.

The message format tests check against fixtures that `Tests/TunnelTests/Fixtures/generate_messages.py` builds from the paper's field tables with Python's `struct` module.

The X25519 tests check the RFC 7748 vectors, the points of small order listed at [cr.yp.to/ecdh.html](https://cr.yp.to/ecdh.html), and fixtures that `Tests/X25519Tests/Fixtures/generate.py` computes from the RFC's formulas with Python's integers. The million-round iterated vector runs when `TUNNEL_LONG_TESTS` is set.

Tests compile and check the usage examples in the README.

## Commits

A commit subject is a sentence in the imperative mood. It starts with a capital letter, has no period and has no type or scope prefix, as in `Reject a zero shared secret`. Names from the code are in backticks.

A pull request has the same sentence as its title. A branch is named for what it does, in lowercase words joined by hyphens, as in `noise-handshake`, with no prefix and no issue number.

## The code

Protocol code is written from the specification: the WireGuard paper and the RFCs it cites. Code translated from another implementation is not accepted. Other implementations are used only from the outside, for interoperability tests and benchmarks.

A change comes with tests, and a test's expected values come from a published vector or an independent implementation.

## What the code protects

Keyed hashing and HMAC wipe their keys and working state after use. A keyed hasher is a noncopyable type, so its key exists in one place. The key and the state are wiped when `finalize()` returns, or when the hasher goes out of scope without being finalized.

Comparing two digests reads every byte, even after a difference is found.

X25519 private keys and shared secrets are noncopyable types, and their bytes are wiped when the value goes out of scope. The X25519 ladder runs the same field operations in the same order for every private key and every public key, swaps values by masking, and wipes every named value that depends on the private key before it returns, the clamped copy of the private key among them. The copy of the public key's u-coordinate and the returned bytes are not wiped. Registers and stack slots that the compiler uses for temporaries are out of Swift's reach, so the wipe stops at the values the code names. A shared secret that comes out all zero throws `X25519SharedSecretError.allZero`. The check combines every byte with OR before it looks at the result.

## Security

Report a vulnerability privately, as [`SECURITY.md`](SECURITY.md) describes.

## License

Contributions are made under the Mozilla Public License 2.0, the license of the repository.
