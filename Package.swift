// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "VDCodable",
	products: [
		.library(name: "VDCodable", targets: ["VDCodable"])
	],
	dependencies: [
		.package(url: "https://github.com/dankinsoid/SimpleCoders.git", from: "1.6.0")
	],
	targets: [
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
