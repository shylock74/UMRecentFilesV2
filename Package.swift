// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "UMRecentFilesV2",
	platforms: [
		.macOS(.v12)
	],
	products: [
		.library(
			name: "UMRecentFilesV2",
			targets: ["UMRecentFilesV2"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/shylock74/UMUIControls", branch: "main"),
	],
	targets: [
		.target(
			name: "UMRecentFilesV2",
			dependencies: [
				.product(name: "UMUIControls", package: "UMUIControls")
			]
		),
		.testTarget(
			name: "UMRecentFilesV2Tests",
			dependencies: ["UMRecentFilesV2"]
		),
	]
)
