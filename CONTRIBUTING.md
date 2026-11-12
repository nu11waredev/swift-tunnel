# Contributing

Issues and pull requests are welcome. For anything larger than a fix, open an issue first so the approach can be agreed before the work is done.

## Building and testing

```
swift build
swift test
```

`scripts/ci.sh` runs both, then `swiftformat --lint` when SwiftFormat is installed. `scripts/install-hooks.sh` makes `git push` run it first.

## The code

Protocol code is written from the specification: the WireGuard paper and the RFCs it cites. Code translated from another implementation is not accepted. Other implementations are used only from the outside, for interoperability tests and benchmarks.

A change comes with tests, and a test's expected values come from a published vector or an independent implementation.

## Security

A vulnerability is reported privately, as `SECURITY.md` describes.

## Licence

Contributions are made under the Mozilla Public License 2.0, the licence of the repository.
