# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

"""Writes kdf-fixtures.json from Python's hashlib and hmac.

Run from this folder: python3 generate.py > kdf-fixtures.json

Kdf_n of the WireGuard paper, section 5.4, is HKDF (RFC 5869) with an empty
info string, the key as the salt and the input as the input keying material:

    t0 = Hmac(key, input)               extract
    t1 = Hmac(t0, 0x01)                 expand
    t2 = Hmac(t0, t1 || 0x02)
    t3 = Hmac(t0, t2 || 0x03)

Hmac is HMAC over BLAKE2s-256. The script first runs the same code over
SHA-256 and checks it against test case 3 of RFC 5869, the case with an empty
salt and an empty info string.
"""

import hashlib
import hmac
import json
import sys


def blake2s_256(data=b""):
    return hashlib.blake2s(data, digest_size=32)


def expand_outputs(hash_function, key, data, count):
    """The first `count` outputs of Kdf, each as long as the hash."""
    t0 = hmac.new(key, data, hash_function).digest()
    outputs = []
    previous = b""
    for counter in range(1, count + 1):
        previous = hmac.new(t0, previous + bytes([counter]), hash_function).digest()
        outputs.append(previous)
    return outputs


def pattern(count, start):
    return bytes((start + index) % 251 for index in range(count))


# RFC 5869, appendix A.3: SHA-256, 22 bytes of 0x0b, no salt, no info, 42 bytes out.
rfc5869_okm = bytes.fromhex(
    "8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d"
    "9d201395faa4b61a96c8"
)
assert b"".join(expand_outputs(hashlib.sha256, b"", b"\x0b" * 22, 2))[:42] == rfc5869_okm

KEY_COUNTS = [0, 1, 32, 63, 64, 65, 200]
INPUT_COUNTS = [0, 1, 32, 63, 64, 65, 200, 1000]

kdf = []
for key_count in KEY_COUNTS:
    key = pattern(key_count, 11)
    for input_count in INPUT_COUNTS:
        data = pattern(input_count, 97)
        first, second, third = expand_outputs(blake2s_256, key, data, 3)
        kdf.append(
            {
                "key": key.hex(),
                "input": data.hex(),
                "output1": first.hex(),
                "output2": second.hex(),
                "output3": third.hex(),
            }
        )

json.dump({"kdf": kdf}, sys.stdout, indent=2)
sys.stdout.write("\n")
