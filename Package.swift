// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package (
	name: "UMRecentFilesV2",
	platforms: [
		.macOS ( .v27 ),
		.iOS ( .v27 )
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library (
			name: "UMRecentFilesV2",
			targets: [ "UMRecentFilesV2" ]
		),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		.package ( url: "https://github.com/shylock74/UMUIControls", branch: "main" ),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target (
			name: "UMRecentFilesV2",
			dependencies: [
				.product ( name: "UMUIControls", package: "UMUIControls" )
			]
		),
		.testTarget (
			name: "UMRecentFilesV2Tests",
			dependencies: [ "UMRecentFilesV2" ]
		),
	]
)