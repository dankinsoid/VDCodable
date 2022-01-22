// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "VDCodable",
	platforms: [
		.macOS(.v10_13),
		.iOS(.v10),
		.tvOS(.v10),
		.watchOS(.v3)
	],
	products: [
		// Products define the executables and libraries produced by a package, and make them visible to other packages.
		.library(
			name: "VDCodable",
			targets: ["VDCodable"]
		),
	],
	dependencies: [
		.package(name: "SimpleCoders", url: "https://github.com/dankinsoid/SimpleCoders.git", from: "1.1.0")
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(
			name: "VDCodable",
			dependencies: ["SimpleCoders"]
		),
		.testTarget(
			name: "VDCodableTests",
			dependencies: ["VDCodable"]
		),
	]
)
