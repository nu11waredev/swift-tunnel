# Contributing

Issues and pull requests are welcome. For anything larger than a fix, open an issue first so the approach can be agreed before the work is done.

## Building and testing

```
swift build
swift test
```

`scripts/check` runs both, then `swiftformat --lint` when SwiftFormat is installed. CI runs the same script. `scripts/install-hooks.sh` makes `git push` run it first.

## Commits

A commit subject is a conventional commit: a type, a colon and a short imperative summary, such as `fix: reject a zero shared secret`. The type is one of `feat`, `fix`, `docs`, `test`, `refactor`, `build`, `ci` or `chore`. A scope in parentheses after the type is optional, as in `feat(x25519): add the shared secret type`. The summary starts in lower case and has no full stop.

## The code

Protocol code is written from the specification: the WireGuard paper and the RFCs it cites. Code translated from another implementation is not accepted. Other implementations are used only from the outside, for interoperability tests and benchmarks.

A change comes with tests, and a test's expected values come from a published vector or an independent implementation.

## Security

A vulnerability is reported privately, as `SECURITY.md` describes.

## Licence

Contributions are made under the Mozilla Public License 2.0, the licence of the repository.
