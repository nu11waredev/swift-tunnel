# Roadmap

swift-tunnel is an implementation of the WireGuard protocol.

The finished library covers the handshake, key derivation, packet encryption, timers and rekeying, routing of packets between peers, and DNS filtering for ads and trackers inside the tunnel.

Each part is tested against published vectors or an independent implementation, and is recorded in `CHANGELOG.md` when it is added to the package.

| Part | Description | State |
| --- | --- | --- |
| BLAKE2s and HMAC-BLAKE2s | BLAKE2s and HMAC-BLAKE2s compute the hash and the message authentication code that the protocol uses throughout. | In the package |
| X25519 | X25519 computes the Diffie-Hellman function behind every key agreement in the handshake. | In the package |
| Key derivation | Key derivation turns handshake secrets into chaining keys and session keys. | In the package |
| Handshake messages | The handshake messages encode and decode the initiation, the response, the cookie reply and the transport data header. | In the package |
| Noise handshake | The Noise handshake authenticates two peers and agrees their session keys. | Next, 2026-11-27 |
| Transport encryption | Transport encryption encrypts packets and uses counters to reject packets that are replayed. | Planned, 2026-12-04 |
| Timers and rekeying | Timers and rekeying send keepalives, retry handshakes and rotate keys, using the time the app passes in. | Planned, 2026-12-11 |
| Peers and routing | Peers and routing map each peer's allowed addresses to its session. | Planned, 2026-12-18 |
| Cookies | Cookies let a server under load answer a handshake message with a cookie reply instead of processing it. | Planned, 2027-01-08 |
| Tunnel state | Tunnel state joins the other parts into one tunnel that takes bytes and the current time and returns bytes. | Planned, 2027-01-15 |
| DNS filtering | DNS filtering applies blocklists for ads and trackers to DNS queries inside the tunnel. | Planned, 2027-01-29 |
