//
// UMRecentFilesV2Tests.swift
// UMRecentFilesV2Tests
//
// Created by Alex Raccuglia on 7 Nov 2026.
//

import XCTest
@testable import UMRecentFilesV2

final class UMRecentFilesV2Tests : XCTestCase {
	func testExample () throws {
		let instance = UMRecentFilesV2 ()
		XCTAssertEqual ( instance.greeting (), "Hello from UMRecentFilesV2!" )
	}
}