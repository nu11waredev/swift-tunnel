// swift-tools-version: 6.2
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import PackageDescription

let package = Package(
  name: "swift-veil",
  platforms: [
    .macOS(.v26),
    .iOS(.v26),
    .tvOS(.v26),
    .watchOS(.v26),
    .visionOS(.v26),
  ],
  products: [
    .library(name: "BLAKE2s", targets: ["BLAKE2s"]),
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
  ],
  swiftLanguageModes: [.v6],
)
