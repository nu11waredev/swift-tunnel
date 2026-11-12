// swift-tools-version: 6.4
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import PackageDescription

let package = Package(
  name: "swift-tunneling",
  platforms: [
    .macOS(.v26),
    .iOS(.v26),
    .tvOS(.v26),
    .watchOS(.v26),
    .visionOS(.v26),
  ],
  products: [
    .library(name: "BLAKE2s", targets: ["BLAKE2s"]),
    .library(name: "X25519", targets: ["X25519"]),
  ],
  targets: [
    .target(
      name: "BLAKE2s",
      swiftSettings: [.enableExperimentalFeature("Lifetimes")],
    ),
    .testTarget(
      name: "BLAKE2sTests",
      dependencies: ["BLAKE2s"],
      exclude: ["Fixtures/generate.py", "Fixtures/README.md", "Resources/README.md"],
      resources: [
        .copy("Resources/blake2s-kat.json"),
        .copy("Fixtures/blake2s-fixtures.json"),
      ],
    ),
    .target(
      name: "X25519",
      swiftSettings: [.enableExperimentalFeature("Lifetimes")],
    ),
    .testTarget(
      name: "X25519Tests",
      dependencies: ["X25519"],
      exclude: ["Fixtures/generate.py", "Fixtures/README.md"],
      resources: [
        .copy("Fixtures/x25519-fixtures.json"),
      ],
    ),
    .target(
      name: "Tunneling",
      dependencies: ["BLAKE2s"],
    ),
    .testTarget(
      name: "TunnelingTests",
      dependencies: ["Tunneling"],
      exclude: ["Fixtures/generate.py", "Fixtures/generate_messages.py", "Fixtures/README.md"],
      resources: [
        .copy("Fixtures/kdf-fixtures.json"),
        .copy("Fixtures/message-fixtures.json"),
      ],
    ),
  ],
  swiftLanguageModes: [.v6],
)
