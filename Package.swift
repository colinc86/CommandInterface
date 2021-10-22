// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CommandInterface",
  products: [
    .library(
      name: "CommandInterface",
      targets: ["CommandInterface"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kareman/SwiftShell", from: "5.1.0"),
  ],
  targets: [
    .target(
      name: "CommandInterface",
      dependencies: ["SwiftShell"]),
    .testTarget(
      name: "CommandInterfaceTests",
      dependencies: ["CommandInterface"]),
  ]
)
