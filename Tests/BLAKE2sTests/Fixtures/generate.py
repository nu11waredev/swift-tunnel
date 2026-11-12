# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

"""Writes blake2s-fixtures.json from Python's hashlib and hmac.

Run from this folder: python3 generate.py > blake2s-fixtures.json

hashlib cannot start BLAKE2s with a byte counter near 2**32, and reaching the
counter's carry by hashing 4 GiB through the Swift tests would take too long.
The counterBoundary fixtures therefore come from a short model of RFC 7693
written below. The script first checks the model against hashlib for counters
that start at zero, then runs it with the counter started near 2**32.
"""

import hashlib
import hmac
import json
import sys


def blake2s_256(data=b""):
    return hashlib.blake2s(data, digest_size=32)


def pattern(count, start):
    return bytes((start + index) % 251 for index in range(count))


MASK = 0xFFFF_FFFF

IV = [
    0x6A09_E667, 0xBB67_AE85, 0x3C6E_F372, 0xA54F_F53A,
    0x510E_527F, 0x9B05_688C, 0x1F83_D9AB, 0x5BE0_CD19,
]

# RFC 7693, section 2.7.
SIGMA = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
    [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
    [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
    [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
    [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
    [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
    [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
    [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
    [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
    [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
]


def rotate_right(value, count):
    return ((value >> count) | (value << (32 - count))) & MASK


def mix(v, a, b, c, d, x, y):
    # RFC 7693, section 3.1, with the BLAKE2s rotations 16, 12, 8 and 7.
    v[a] = (v[a] + v[b] + x) & MASK
    v[d] = rotate_right(v[d] ^ v[a], 16)
    v[c] = (v[c] + v[d]) & MASK
    v[b] = rotate_right(v[b] ^ v[c], 12)
    v[a] = (v[a] + v[b] + y) & MASK
    v[d] = rotate_right(v[d] ^ v[a], 8)
    v[c] = (v[c] + v[d]) & MASK
    v[b] = rotate_right(v[b] ^ v[c], 7)


def compress(h, block, counter, is_final):
    # RFC 7693, section 3.2. The counter is split into t0 and t1.
    m = [int.from_bytes(block[4 * i : 4 * i + 4], "little") for i in range(16)]
    v = h + IV
    v[12] ^= counter & MASK
    v[13] ^= (counter >> 32) & MASK
    if is_final:
        v[14] ^= MASK
    for round_index in range(10):
        s = SIGMA[round_index]
        mix(v, 0, 4, 8, 12, m[s[0]], m[s[1]])
        mix(v, 1, 5, 9, 13, m[s[2]], m[s[3]])
        mix(v, 2, 6, 10, 14, m[s[4]], m[s[5]])
        mix(v, 3, 7, 11, 15, m[s[6]], m[s[7]])
        mix(v, 0, 5, 10, 15, m[s[8]], m[s[9]])
        mix(v, 1, 6, 11, 12, m[s[10]], m[s[11]])
        mix(v, 2, 7, 8, 13, m[s[12]], m[s[13]])
        mix(v, 3, 4, 9, 14, m[s[14]], m[s[15]])
    return [h[i] ^ v[i] ^ v[i + 8] for i in range(8)]


def model_blake2s_256(data, start=0):
    """Unkeyed BLAKE2s-256 of RFC 7693 with the byte counter started at `start`."""
    h = list(IV)
    h[0] ^= 0x0101_0000 ^ 32
    blocks = [data[i : i + 64] for i in range(0, len(data), 64)] or [b""]
    counter = start
    for index, block in enumerate(blocks):
        counter += len(block)
        h = compress(h, block.ljust(64, b"\0"), counter, index == len(blocks) - 1)
    return b"".join(word.to_bytes(4, "little") for word in h)


MESSAGE_COUNTS = [0, 1, 63, 64, 65, 200]
KEY_COUNTS = [1, 16, 31, 32]
HMAC_KEY_COUNTS = [0, 1, 32, 63, 64, 65, 200]
HMAC_MESSAGE_COUNTS = [0, 1, 64, 1000]

blake2s = []
for digest_count in range(1, 33):
    key_counts = sorted({*KEY_COUNTS, (digest_count * 7) % 32 + 1})
    for message_count in MESSAGE_COUNTS:
        message = pattern(message_count, digest_count)
        for key_count in [0] + key_counts:
            key = pattern(key_count, 100 + digest_count)
            output = hashlib.blake2s(message, digest_size=digest_count, key=key).hexdigest()
            blake2s.append(
                {"digestCount": digest_count, "key": key.hex(), "input": message.hex(), "output": output}
            )

hmac_blake2s = []
for key_count in HMAC_KEY_COUNTS:
    key = pattern(key_count, 7)
    for message_count in HMAC_MESSAGE_COUNTS:
        message = pattern(message_count, 50)
        output = hmac.new(key, message, blake2s_256).hexdigest()
        hmac_blake2s.append({"key": key.hex(), "input": message.hex(), "output": output})

# The model must agree with hashlib wherever hashlib can be asked.
for message_count in [0, 1, 63, 64, 65, 127, 128, 129, 1000]:
    message = pattern(message_count, 3)
    assert model_blake2s_256(message) == blake2s_256(message).digest()

COUNTER_STARTS = [0xFFFF_FFC0, 0xFFFF_FFF0, 0xFFFF_FFFF, 0x1_FFFF_FFC0]
COUNTER_MESSAGE_COUNTS = [1, 63, 64, 65, 200]

counter_boundary = []
for start in COUNTER_STARTS:
    for message_count in COUNTER_MESSAGE_COUNTS:
        message = pattern(message_count, 9)
        output = model_blake2s_256(message, start).hex()
        counter_boundary.append({"start": start, "input": message.hex(), "output": output})

json.dump(
    {"blake2s": blake2s, "hmac": hmac_blake2s, "counterBoundary": counter_boundary},
    sys.stdout,
    indent=2,
)
sys.stdout.write("\n")
