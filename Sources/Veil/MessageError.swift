// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// Why bytes do not parse as a message of the WireGuard paper, section 5.4.
/// A parse checks the length first, then the type byte, then the reserved
/// bytes.
package enum MessageError: Error, Equatable {
  /// The bytes are not the length the message type has.
  case wrongLength
  /// The first byte names none of the four message types.
  case unknownType
  /// The first byte is the type of another message, not the one being parsed.
  case wrongType
  /// One of the three reserved bytes after the type is not zero.
  case nonzeroReserved
}
