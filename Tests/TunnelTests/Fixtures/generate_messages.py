# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

"""Writes message-fixtures.json with Python's struct module.

Run from this folder: python3 generate_messages.py > message-fixtures.json

Each message is packed from the field tables of the WireGuard paper, section
5.4. Integers are little-endian, and an encrypted field is its plaintext
length plus the 16-byte Poly1305 tag:

    initiation, 5.4.2     type 0x1, reserved 0^3, sender (4), ephemeral (32),
                          static (32 + 16), timestamp (12 + 16), mac1 (16),
                          mac2 (16)
    response, 5.4.3       type 0x2, reserved 0^3, sender (4), receiver (4),
                          ephemeral (32), empty (0 + 16), mac1 (16), mac2 (16)
    cookie reply, 5.4.7   type 0x3, reserved 0^3, receiver (4), nonce (24),
                          cookie (16 + 16)
    transport data, 5.4.6 type 0x4, reserved 0^3, receiver (4), counter (8),
                          packet (the padded packet + 16)

For the two handshake messages, mac1 covers every byte before mac1 and mac2
every byte before mac2 (section 5.4.4). Those prefixes are packed again on
their own, from the fields before the MAC, rather than sliced out of the
whole message.
"""

import json
import struct
import sys

TAG = 16

INITIATION = struct.Struct("<B3xI32s%ds%ds16s16s" % (32 + TAG, 12 + TAG))
INITIATION_BEFORE_MAC1 = struct.Struct("<B3xI32s%ds%ds" % (32 + TAG, 12 + TAG))
RESPONSE = struct.Struct("<B3xII32s%ds16s16s" % (0 + TAG))
RESPONSE_BEFORE_MAC1 = struct.Struct("<B3xII32s%ds" % (0 + TAG))
COOKIE_REPLY = struct.Struct("<B3xI24s%ds" % (16 + TAG))
TRANSPORT_HEADER = struct.Struct("<B3xIQ")

assert INITIATION.size == 148
assert RESPONSE.size == 92
assert COOKIE_REPLY.size == 64
assert TRANSPORT_HEADER.size == 16


def pattern(count, start):
    """Bytes that differ from field to field, so a field read from the wrong
    offset shows."""
    return bytes((start + index) % 251 for index in range(count))


# Indices and counters chosen so a byte-order mistake changes the value.
INDICES = [0, 1, 0x04030201, 0xFFFFFFFE]
COUNTERS = [0, 1, 0x0807060504030201, 0xFFFFFFFFFFFFFFFF]


def initiation(case):
    start = 40 * case
    sender = INDICES[case]
    ephemeral = pattern(32, start + 1)
    encrypted_static = pattern(32 + TAG, start + 2)
    encrypted_timestamp = pattern(12 + TAG, start + 3)
    mac1 = pattern(16, start + 4)
    # Section 5.4.4: mac2 is zero when there is no recent cookie.
    mac2 = bytes(16) if case == 0 else pattern(16, start + 5)
    fields = (1, sender, ephemeral, encrypted_static, encrypted_timestamp)
    before_mac1 = INITIATION_BEFORE_MAC1.pack(*fields)
    return {
        "message": INITIATION.pack(*fields, mac1, mac2).hex(),
        "sender": sender,
        "ephemeral": ephemeral.hex(),
        "encryptedStatic": encrypted_static.hex(),
        "encryptedTimestamp": encrypted_timestamp.hex(),
        "mac1": mac1.hex(),
        "mac2": mac2.hex(),
        "mac1Input": before_mac1.hex(),
        "mac2Input": (before_mac1 + mac1).hex(),
    }


def response(case):
    start = 40 * case + 7
    sender = INDICES[case]
    receiver = INDICES[(case + 1) % len(INDICES)]
    ephemeral = pattern(32, start + 1)
    encrypted_empty = pattern(0 + TAG, start + 2)
    mac1 = pattern(16, start + 3)
    mac2 = bytes(16) if case == 0 else pattern(16, start + 4)
    fields = (2, sender, receiver, ephemeral, encrypted_empty)
    before_mac1 = RESPONSE_BEFORE_MAC1.pack(*fields)
    return {
        "message": RESPONSE.pack(*fields, mac1, mac2).hex(),
        "sender": sender,
        "receiver": receiver,
        "ephemeral": ephemeral.hex(),
        "encryptedEmpty": encrypted_empty.hex(),
        "mac1": mac1.hex(),
        "mac2": mac2.hex(),
        "mac1Input": before_mac1.hex(),
        "mac2Input": (before_mac1 + mac1).hex(),
    }


def cookie_reply(case):
    start = 40 * case + 13
    receiver = INDICES[case]
    nonce = pattern(24, start + 1)
    encrypted_cookie = pattern(16 + TAG, start + 2)
    return {
        "message": COOKIE_REPLY.pack(3, receiver, nonce, encrypted_cookie).hex(),
        "receiver": receiver,
        "nonce": nonce.hex(),
        "encryptedCookie": encrypted_cookie.hex(),
    }


# The packet is the padded plaintext plus the tag. Section 5.4.6 pads to a
# multiple of 16 but never past the MTU, so other lengths can arrive: 16 is a
# keepalive (an empty packet), 33 is a packet whose padding the MTU cut short.
PACKET_COUNTS = [16, 33, 48, 1440]


def transport_data(case):
    receiver = INDICES[case]
    counter = COUNTERS[case]
    packet = pattern(PACKET_COUNTS[case], 40 * case + 17)
    header = TRANSPORT_HEADER.pack(4, receiver, counter)
    return {
        "message": (header + packet).hex(),
        "receiver": receiver,
        "counter": counter,
        "packet": packet.hex(),
    }


CASES = range(4)
json.dump(
    {
        "initiation": [initiation(case) for case in CASES],
        "response": [response(case) for case in CASES],
        "cookieReply": [cookie_reply(case) for case in CASES],
        "transportData": [transport_data(case) for case in CASES],
    },
    sys.stdout,
    indent=2,
)
sys.stdout.write("\n")
