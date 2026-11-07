# UMRecentFilesV2

A reusable Swift package library generated with **SUP (Start Up Project)**.

## Overview
`UMRecentFilesV2` is a Swift Package library built for macOS 27.0+.

## Installation

### Swift Package Manager
Add `UMRecentFilesV2` as a dependency in your `Package.swift`:

```swift
dependencies: [
	.package ( url: "https://github.com/shylock74/UMRecentFilesV2.git", branch: "main" )
]
```

Then add `UMRecentFilesV2` to your target dependencies:

```swift
.target (
	name: "YourTarget",
	dependencies: [
		.product ( name: "UMRecentFilesV2", package: "UMRecentFilesV2" )
	]
)
```

## Integrated Dependencies
- **UMUIControls** (Remote: [https://github.com/shylock74/UMUIControls](https://github.com/shylock74/UMUIControls)) - Branch: main

## Requirements
- macOS 27.0+
- Swift 5.9+
- Xcode 15.0 or later

## License
Copyright © 2026 Ulti.Media. All rights reserved.