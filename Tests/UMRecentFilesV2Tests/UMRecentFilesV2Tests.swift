//
//  UMRecentFilesV2Tests.swift
//  UMRecentFilesV2Tests
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import XCTest
@testable import UMRecentFilesV2

final class UMRecentFilesV2Tests: XCTestCase {

	var tempDirectory: URL!

	override func setUpWithError() throws {
		tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
	}

	override func tearDownWithError() throws {
		try? FileManager.default.removeItem(at: tempDirectory)
	}

	func testRecentFileCreationAndDefaults() {
		let testURL = tempDirectory.appendingPathComponent("Project.mp4")
		let item = UMRecentFile(url: testURL)

		XCTAssertEqual(item.name, "Project.mp4")
		XCTAssertEqual(item.fileExtension, "mp4")
		XCTAssertEqual(item.displayNameWithoutExtension, "Project")
		XCTAssertFalse(item.isPinned)
	}

	func testRecentFileRetrocompatibleDecoding() throws {
		// Old JSON structure with only id, name and url
		let jsonString = """
		{
			"id": "12345-67890",
			"name": "LegacyFile.wav",
			"url": "file:///tmp/LegacyFile.wav"
		}
		"""
		let data = try XCTUnwrap(jsonString.data(using: .utf8))
		let file = try JSONDecoder().decode(UMRecentFile.self, from: data)

		XCTAssertEqual(file.id, "12345-67890")
		XCTAssertEqual(file.name, "LegacyFile.wav")
		XCTAssertEqual(file.url.path, "/tmp/LegacyFile.wav")
		XCTAssertFalse(file.isPinned)
	}

	func testManagerAddAndDeduplication() {
		let prefsKey = "TestPrefs_\(UUID().uuidString)"
		let manager = UMRecentFiles(prefsKey, sourceMode: .customOnly, maxCount: 3)

		let url1 = tempDirectory.appendingPathComponent("File1.txt")
		let url2 = tempDirectory.appendingPathComponent("File2.txt")
		let url3 = tempDirectory.appendingPathComponent("File3.txt")
		let url4 = tempDirectory.appendingPathComponent("File4.txt")

		manager.addFile(url: url1)
		manager.addFile(url: url2)
		manager.addFile(url: url3)

		XCTAssertEqual(manager.fileList.count, 3)
		XCTAssertEqual(manager.fileList.first?.url, url3)

		// Adding existing file bumps it to the top without duplicating
		manager.addFile(url: url1)
		XCTAssertEqual(manager.fileList.count, 3)
		XCTAssertEqual(manager.fileList.first?.url, url1)

		// Adding 4th file respects maxCount
		manager.addFile(url: url4)
		XCTAssertEqual(manager.fileList.count, 3)
		XCTAssertEqual(manager.fileList.first?.url, url4)
	}

	func testManagerPinningLogic() {
		let prefsKey = "TestPrefs_\(UUID().uuidString)"
		let manager = UMRecentFiles(prefsKey, sourceMode: .customOnly, maxCount: 5)

		let url1 = tempDirectory.appendingPathComponent("File1.txt")
		let url2 = tempDirectory.appendingPathComponent("File2.txt")

		manager.addFile(url: url1)
		manager.addFile(url: url2)

		guard let file1 = manager.fileList.first(where: { $0.url == url1 }) else {
			XCTFail("File1 not found")
			return
		}

		// Pin File1
		manager.togglePin(file1)
		XCTAssertTrue(manager.fileList.first(where: { $0.url == url1 })?.isPinned == true)

		// Pinned items stay at top even when clearAll(keepPinned: true) is called
		manager.clearAll(keepPinned: true)
		XCTAssertEqual(manager.fileList.count, 1)
		XCTAssertEqual(manager.fileList.first?.url, url1)
	}

	func testFilterAndSearch() {
		let prefsKey = "TestPrefs_\(UUID().uuidString)"
		let manager = UMRecentFiles(prefsKey, sourceMode: .customOnly, maxCount: 10)

		let videoURL = tempDirectory.appendingPathComponent("Edit.mov")
		let audioURL = tempDirectory.appendingPathComponent("Voiceover.wav")

		// Create files physically so existsOnDisk is true
		FileManager.default.createFile(atPath: videoURL.path, contents: Data())
		FileManager.default.createFile(atPath: audioURL.path, contents: Data())

		manager.addFile(url: videoURL)
		manager.addFile(url: audioURL)

		// Filter by extension
		let audioFiles = manager.filteredFiles(filterExtensions: ["wav"], hideMissingFiles: true)
		XCTAssertEqual(audioFiles.count, 1)
		XCTAssertEqual(audioFiles.first?.url, audioURL)

		// Filter by search string
		let searchResults = manager.filteredFiles(searchText: "Voice", hideMissingFiles: true)
		XCTAssertEqual(searchResults.count, 1)
		XCTAssertEqual(searchResults.first?.url, audioURL)
	}

	func testAppDocumentTypesResolution() {
		// Explicit extensions override
		let explicit = ["mov", "mp4"]
		let resolved = UMAppDocumentTypes.resolveExtensions(explicitExtensions: explicit)
		XCTAssertEqual(resolved, ["mov", "mp4"])

		// Fallback from recent files when explicit is empty
		let testFile = UMRecentFile(url: URL(fileURLWithPath: "/tmp/sample.fcpxml"))
		let fallback = UMAppDocumentTypes.resolveExtensions(explicitExtensions: [], fallbackFromFiles: [testFile])
		XCTAssertTrue(fallback.contains("fcpxml"))
	}

	func testFileSearchCoordinatorSpotlightQuery() {
		let coordinator = UMFileSearchCoordinator()
		let expectation = XCTestExpectation(description: "Spotlight query completes or gathers results")

		coordinator.startSystemWideSearch(extensions: ["swift"], limit: 50)

		DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
			// On macOS, swift files always exist on system
			XCTAssertGreaterThan(coordinator.discoveredFiles.count, 0)
			coordinator.stopSearch()
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 4.0)
	}

	func testFileSearchCoordinatorFolderScan() {
		let coordinator = UMFileSearchCoordinator()

		// Create files in temp directory
		let fileA = tempDirectory.appendingPathComponent("ProjectA.testext")
		let fileB = tempDirectory.appendingPathComponent("ProjectB.testext")
		let fileC = tempDirectory.appendingPathComponent("IgnoreMe.other")

		FileManager.default.createFile(atPath: fileA.path, contents: Data())
		FileManager.default.createFile(atPath: fileB.path, contents: Data())
		FileManager.default.createFile(atPath: fileC.path, contents: Data())

		let expectation = XCTestExpectation(description: "Folder search completes")

		coordinator.searchInFolder(folderURL: tempDirectory, extensions: ["testext"], limit: 10)

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			XCTAssertEqual(coordinator.discoveredFiles.count, 2)
			XCTAssertFalse(coordinator.isSearching)
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 2.0)
	}
}
