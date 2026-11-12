# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

"""Writes x25519-fixtures.json from the formulas of RFC 7748, section 5.

Run from this folder: python3 generate.py > x25519-fixtures.json

The arithmetic is Python's integers reduced modulo p, with the inverse taken
as pow(z, p - 2, p), as the RFC writes it. The script checks itself against
the RFC's vectors in sections 5.2 and 6.1 before it writes anything.
"""

import hashlib
import json
import sys

P = 2**255 - 19
A24 = 121665


def decode_little_endian(b):
    return sum(byte << (8 * index) for index, byte in enumerate(b))


def decode_u_coordinate(u):
    u = bytearray(u)
    u[31] &= 127
    return decode_little_endian(u)


def encode_u_coordinate(u):
    u %= P
    return bytes((u >> (8 * index)) & 0xFF for index in range(32))


def decode_scalar(k):
    k = bytearray(k)
    k[0] &= 248
    k[31] &= 127
    k[31] |= 64
    return decode_little_endian(k)


def x25519(k, u):
    """The ladder of RFC 7748, section 5, with cswap as a plain exchange."""
    k = decode_scalar(k)
    x_1 = decode_u_coordinate(u)
    x_2, z_2, x_3, z_3 = 1, 0, x_1, 1
    swap = 0
    for t in reversed(range(255)):
        k_t = (k >> t) & 1
        swap ^= k_t
        if swap:
            x_2, x_3 = x_3, x_2
            z_2, z_3 = z_3, z_2
        swap = k_t
        a = (x_2 + z_2) % P
        aa = a * a % P
        b = (x_2 - z_2) % P
        bb = b * b % P
        e = (aa - bb) % P
        c = (x_3 + z_3) % P
        d = (x_3 - z_3) % P
        da = d * a % P
        cb = c * b % P
        x_3 = (da + cb) ** 2 % P
        z_3 = x_1 * (da - cb) ** 2 % P
        x_2 = aa * bb % P
        z_2 = e * (aa + A24 * e) % P
    if swap:
        x_2, x_3 = x_3, x_2
        z_2, z_3 = z_3, z_2
    return encode_u_coordinate(x_2 * pow(z_2, P - 2, P))


def number_bytes(n):
    return n.to_bytes(32, "little")


def pattern(label, index):
    return hashlib.sha256(f"{label} {index}".encode()).digest()


ZERO = bytes(32)
BASE = number_bytes(9)


def check_rfc_vectors():
    # Section 5.2, the two input and output pairs.
    pairs = [
        (
            "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4",
            "e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c",
            "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552",
        ),
        (
            "4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d",
            "e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493",
            "95cbde9476e8907d7aade45cb4b873f88b595a68799fa152e6f8f7647aac7957",
        ),
    ]
    for k, u, out in pairs:
        assert x25519(bytes.fromhex(k), bytes.fromhex(u)).hex() == out

    # Section 5.2, the iterated test after one iteration.
    assert x25519(BASE, BASE).hex() == (
        "422c8e7a6227d7bca1350b3e2bb7279f7897b87bb6854b783c60e80311ae3079"
    )

    # Section 6.1.
    a = bytes.fromhex("77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a")
    b = bytes.fromhex("5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb")
    k_a = x25519(a, BASE)
    k_b = x25519(b, BASE)
    assert k_a.hex() == "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"
    assert k_b.hex() == "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"
    shared = "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742"
    assert x25519(a, k_b).hex() == shared
    assert x25519(b, k_a).hex() == shared


# The u-coordinates of points of small order listed on https://cr.yp.to/ecdh.html,
# under "How do I validate Curve25519 public keys?", that are below 2**255.
LOW_ORDER = [
    0,
    1,
    325606250916557431795983626356110631294008115727848805560023387167927233504,
    39382357235489614581723060781553021112529911719440698176882885853963445705823,
    P - 1,
    P,
    P + 1,
]


def low_order_fixtures():
    encodings = [number_bytes(u) for u in LOW_ORDER]
    encodings += [number_bytes(u + 2**255) for u in LOW_ORDER]
    for u in encodings:
        for index in range(4):
            assert x25519(pattern("low order scalar", index), u) == ZERO
    return [u.hex() for u in encodings]


def exchange(scalar, u):
    output = x25519(scalar, u)
    assert output != ZERO
    return {"scalar": scalar.hex(), "u": u.hex(), "output": output.hex()}


def non_canonical_fixtures():
    # 2**255 - 19 + 2 through 2**255 - 1. P and P + 1 are in the low-order list.
    scalar = pattern("non-canonical scalar", 0)
    return [exchange(scalar, number_bytes(u)) for u in range(P + 2, 2**255)]


def top_bit_fixtures():
    fixtures = []
    for index in range(8):
        u = bytearray(pattern("top bit u", index))
        u[31] |= 128
        fixtures.append(exchange(pattern("top bit scalar", index), bytes(u)))
    return fixtures


def exchange_fixtures():
    return [exchange(pattern("scalar", index), pattern("u", index)) for index in range(32)]


def main():
    check_rfc_vectors()
    fixtures = {
        "lowOrder": low_order_fixtures(),
        "nonCanonical": non_canonical_fixtures(),
        "topBit": top_bit_fixtures(),
        "exchange": exchange_fixtures(),
    }
    json.dump(fixtures, sys.stdout, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
