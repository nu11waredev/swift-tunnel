# Fixtures

`kdf-fixtures.json` is written by `generate.py` from Python's hashlib and hmac. Run `python3 generate.py > kdf-fixtures.json` in this folder. The script uses only the standard library, and it checks its HKDF code against RFC 5869, test case 3, before it writes. `KeyDerivationTests.swift` reads the file.

`message-fixtures.json` is written by `generate_messages.py`, which packs each message of section 5.4 of the WireGuard paper with Python's struct module from the paper's field tables. Run `python3 generate_messages.py > message-fixtures.json` in this folder. The script uses only the standard library. The message tests read the file.
