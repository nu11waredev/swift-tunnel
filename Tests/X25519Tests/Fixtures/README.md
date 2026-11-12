# Fixtures

`x25519-fixtures.json` is written by `generate.py` from the formulas of RFC 7748, section 5, in Python's integers, with the inverse taken as `pow(z, p - 2, p)`. Run `python3 generate.py > x25519-fixtures.json` in this folder. The script uses only the standard library, and it checks itself against the RFC's vectors in sections 5.2 and 6.1 before it writes. `FixtureTests.swift` reads the file.

`lowOrder` holds the u-coordinates of points of small order listed at [cr.yp.to/ecdh.html](https://cr.yp.to/ecdh.html), under "How do I validate Curve25519 public keys?": 0, 1, the two points of order 8, and 2^255 − 19 − 1, 2^255 − 19 and 2^255 − 19 + 1, each as written and again with bit 255 set. The page's other five values are 2^255 or more, and once bit 255 is masked, as RFC 7748 requires, they are no longer points of small order. The script checks that every entry gives the all-zero output.

`nonCanonical` covers each u-coordinate from 2^255 − 19 + 2 to 2^255 − 1. `topBit` has bit 255 set in every u-coordinate. `exchange` is 32 scalar and u-coordinate pairs taken from SHA-256 of a label and a counter.
