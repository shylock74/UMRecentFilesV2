//
//  UMRecentFiles.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import Foundation
import AppKit
import Combine

/// Main manager for recent files.
/// Conforms to ObservableObject for direct binding in SwiftUI while preserving legacy static APIs.
public class UMRecentFiles: ObservableObject, Codable, @unchecked Sendable {

	// MARK: - Constants
	public static let kDefaultPrefsKey = "UMRecentFiles"
	public static let shared = UMRecentFiles()

	// MARK: - Published / Public Properties
	public var prefsKey: String
	public var maxCount: Int = 20
	public var sourceMode: UMRecentFilesSourceMode = .hybrid

	@Published public var fileList: [UMRecentFile] = []

	// MARK: - Internal Storage Codable Container
	private struct StoragePayload: Codable {
		var prefsKey: String
		var fileList: [UMRecentFile]
		var maxCount: Int
	}

	// MARK: - Codable Implementation
	private enum CodingKeys: String, CodingKey {
		case prefsKey
		case fileList
		case maxCount
	}

	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.prefsKey = (try? container.decodeIfPresent(String.self, forKey: .prefsKey)) ?? Self.kDefaultPrefsKey
		self.fileList = (try? container.decodeIfPresent([UMRecentFile].self, forKey: .fileList)) ?? []
		self.maxCount = (try? container.decodeIfPresent(Int.self, forKey: .maxCount)) ?? 20
		self.sourceMode = .hybrid
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(prefsKey, forKey: .prefsKey)
		try container.encode(fileList, forKey: .fileList)
		try container.encode(maxCount, forKey: .maxCount)
	}

	// MARK: - Initializer
	public init(
		_ prefsKey: String? = nil,
		sourceMode: UMRecentFilesSourceMode = .hybrid,
		maxCount: Int = 20
	) {
		self.prefsKey = prefsKey ?? Self.kDefaultPrefsKey
		self.sourceMode = sourceMode
		self.maxCount = maxCount

		load()
		if sourceMode != .customOnly {
			syncWithSystemRecents()
		}
	}

	// MARK: - Persistence
	public func save() {
		let payload = StoragePayload(prefsKey: prefsKey, fileList: fileList, maxCount: maxCount)
		if let data = try? JSONEncoder().encode(payload),
		   let string = String(data: data, encoding: .utf8) {
			UserDefaults.standard.set(string, forKey: prefsKey)
		}
	}

	public func load() {
		guard let raw = UserDefaults.standard.string(forKey: prefsKey),
			  let data = raw.data(using: .utf8) else {
			return
		}

		if let payload = try? JSONDecoder().decode(StoragePayload.self, from: data) {
			self.fileList = payload.fileList
			self.maxCount = payload.maxCount
		} else if let legacyFiles = try? JSONDecoder().decode([UMRecentFile].self, from: data) {
			self.fileList = legacyFiles
		}
	}

	// MARK: - System Synchronization
	public func syncWithSystemRecents() {
		guard sourceMode != .customOnly else { return }

		let systemURLs = NSDocumentController.shared.recentDocumentURLs
		var updatedList = fileList

		// Add system URLs that are not yet tracked
		for url in systemURLs {
			if !updatedList.contains(where: { $0.url == url }) {
				let file = UMRecentFile(url: url)
				updatedList.append(file)
			}
		}

		// Enforce maximum capacity while preserving pinned items
		let pinned = updatedList.filter { $0.isPinned }
		var unpinned = updatedList.filter { !$0.isPinned }
		if unpinned.count > maxCount {
			unpinned = Array(unpinned.prefix(maxCount))
		}

		self.fileList = pinned + unpinned
	}

	// MARK: - File Management API
	public func addFile(name: String? = nil, url: URL, notifySystem: Bool = true) {
		// Remove existing entry for the same URL
		let existingPin = fileList.first(where: { $0.url == url })?.isPinned ?? false
		fileList.removeAll(where: { $0.url == url })

		let newFile = UMRecentFile(
			name: name,
			url: url,
			lastOpenedDate: Date(),
			isPinned: existingPin
		)

		// Insert at top of its section (pinned stay at very top)
		if newFile.isPinned {
			fileList.insert(newFile, at: 0)
		} else {
			let firstUnpinnedIndex = fileList.firstIndex(where: { !$0.isPinned }) ?? fileList.count
			fileList.insert(newFile, at: firstUnpinnedIndex)
		}

		// Cap unpinned items
		let pinnedItems = fileList.filter { $0.isPinned }
		var unpinnedItems = fileList.filter { !$0.isPinned }
		if unpinnedItems.count > maxCount {
			unpinnedItems = Array(unpinnedItems.prefix(maxCount))
		}
		fileList = pinnedItems + unpinnedItems

		save()

		if notifySystem && sourceMode != .customOnly {
			NSDocumentController.shared.noteNewRecentDocumentURL(url)
		}
	}

	public func removeRecentFile(_ recentFile: UMRecentFile) {
		fileList.removeAll(where: { $0.id == recentFile.id || $0.url == recentFile.url })
		save()
	}

	public func removeRecentFile(withUrl url: URL) {
		fileList.removeAll(where: { $0.url == url })
		save()
	}

	public func togglePin(_ recentFile: UMRecentFile) {
		if let index = fileList.firstIndex(where: { $0.id == recentFile.id }) {
			fileList[index].isPinned.toggle()
			sortFiles(by: .lastOpened)
			save()
		}
	}

	public func setPinned(_ pinned: Bool, for url: URL) {
		if let index = fileList.firstIndex(where: { $0.url == url }) {
			fileList[index].isPinned = pinned
			sortFiles(by: .lastOpened)
			save()
		}
	}

	public func clearAll(keepPinned: Bool = true) {
		if keepPinned {
			fileList = fileList.filter { $0.isPinned }
		} else {
			fileList.removeAll()
		}
		save()
	}

	public func pruneMissingFiles() {
		fileList.removeAll(where: { !$0.existsOnDisk })
		save()
	}

	// MARK: - Sorting & Filtering
	public func sortedFiles(by order: UMRecentFilesSortOrder) -> [UMRecentFile] {
		let pinned = fileList.filter { $0.isPinned }
		let unpinned = fileList.filter { !$0.isPinned }

		let sortClosure: (UMRecentFile, UMRecentFile) -> Bool = { a, b in
			switch order {
			case .lastOpened:
				return a.lastOpenedDate > b.lastOpenedDate
			case .dateModified:
				return (a.modificationDate ?? .distantPast) > (b.modificationDate ?? .distantPast)
			case .name:
				return a.name.localizedStandardCompare(b.name) == .orderedAscending
			case .size:
				return (a.fileSize ?? 0) > (b.fileSize ?? 0)
			}
		}

		return pinned.sorted(by: sortClosure) + unpinned.sorted(by: sortClosure)
	}

	public func sortFiles(by order: UMRecentFilesSortOrder) {
		self.fileList = sortedFiles(by: order)
	}

	public func filteredFiles(
		filterExtensions: [String] = [],
		searchText: String = "",
		sortOrder: UMRecentFilesSortOrder = .lastOpened,
		hideMissingFiles: Bool = true
	) -> [UMRecentFile] {
		var list = sortedFiles(by: sortOrder)

		if hideMissingFiles {
			list = list.filter { $0.existsOnDisk }
		}

		if !filterExtensions.isEmpty {
			let normalized = filterExtensions.map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
			list = list.filter { normalized.contains($0.fileExtension) }
		}

		if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			list = list.filter {
				UMRecentFileHelpers.searchContains(source: $0.name, query: searchText) ||
				UMRecentFileHelpers.searchContains(source: $0.url.path, query: searchText)
			}
		}

		return list
	}

	// MARK: - Static Backward-Compatible APIs
	public static func addFile(name: String? = nil, url: URL) {
		shared.addFile(name: name, url: url)
	}

	public static func removeRecentFile(_ recentFile: UMRecentFile) {
		shared.removeRecentFile(recentFile)
	}

	public static func removeRecentFile(withUrl url: URL) {
		shared.removeRecentFile(withUrl: url)
	}

	public static func fillRecentFilesMenu(
		menu: NSMenuItem,
		selectedFileCallback: @escaping ((URL) -> Void)
	) {
		shared.fillRecentFilesMenu(menu: menu, selectedFileCallback: selectedFileCallback)
	}

	// MARK: - AppKit NSMenuItem Integration
	public func fillRecentFilesMenu(
		menu: NSMenuItem,
		selectedFileCallback: @escaping ((URL) -> Void)
	) {
		let submenu = NSMenu(title: menu.title)

		let availableFiles = fileList.filter { $0.existsOnDisk }

		if availableFiles.isEmpty {
			let emptyItem = NSMenuItem(title: "No Recent Files", action: nil, keyEquivalent: "")
			emptyItem.isEnabled = false
			submenu.addItem(emptyItem)
		} else {
			let pinned = availableFiles.filter { $0.isPinned }
			let unpinned = availableFiles.filter { !$0.isPinned }

			func addItem(for file: UMRecentFile) {
				let itemTitle = file.isPinned ? "📌 \(file.name)" : file.name
				let item = NSMenuItem(title: itemTitle, action: #selector(MenuTarget.menuItemSelected(_:)), keyEquivalent: "")
				item.image = NSWorkspace.shared.icon(forFile: file.url.path)
				item.image?.size = NSSize(width: 16, height: 16)
				item.target = MenuTarget.shared
				item.representedObject = file.url
				MenuTarget.shared.registerCallback(for: file.url, callback: selectedFileCallback)
				submenu.addItem(item)
			}

			pinned.forEach { addItem(for: $0) }
			if !pinned.isEmpty && !unpinned.isEmpty {
				submenu.addItem(NSMenuItem.separator())
			}
			unpinned.forEach { addItem(for: $0) }

			submenu.addItem(NSMenuItem.separator())
			let clearItem = NSMenuItem(title: "Clear Menu", action: #selector(MenuTarget.clearRecentFiles(_:)), keyEquivalent: "")
			clearItem.target = MenuTarget.shared
			MenuTarget.shared.clearHandler = { [weak self] in
				self?.clearAll(keepPinned: true)
			}
			submenu.addItem(clearItem)
		}

		menu.submenu = submenu
	}

	// Internal helper target for NSMenuItem actions
	private final class MenuTarget: NSObject {
		static let shared = MenuTarget()
		private var callbacks: [URL: (URL) -> Void] = [:]
		var clearHandler: (() -> Void)?

		func registerCallback(for url: URL, callback: @escaping (URL) -> Void) {
			callbacks[url] = callback
		}

		@objc func menuItemSelected(_ sender: NSMenuItem) {
			guard let url = sender.representedObject as? URL,
				  let callback = callbacks[url] else { return }
			callback(url)
		}

		@objc func clearRecentFiles(_ sender: NSMenuItem) {
			clearHandler?()
		}
	}
}

