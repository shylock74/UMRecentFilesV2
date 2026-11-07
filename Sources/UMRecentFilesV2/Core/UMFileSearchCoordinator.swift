//
//  UMFileSearchCoordinator.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import Foundation
import Combine
import AppKit

/// Coordinates system-wide (Spotlight / NSMetadataQuery) and custom folder recursive searches
/// with real-time batched streaming of discovered files to SwiftUI.
public final class UMFileSearchCoordinator: ObservableObject, @unchecked Sendable {

	// MARK: - Published Properties
	@Published public private(set) var isSearching: Bool = false
	@Published public private(set) var discoveredFiles: [UMRecentFile] = []
	@Published public private(set) var searchStatusMessage: String = ""
	@Published public private(set) var currentSearchTargetName: String = "Macintosh"

	// MARK: - Internal State
	private var metadataQuery: NSMetadataQuery?
	private var queryCancellable: AnyCancellable?
	private var searchWorkItem: DispatchWorkItem?
	private var pendingURLs: [URL] = []
	private var discoveredURLsSet: Set<URL> = []
	private var flushTimer: Timer?
	private let queue = DispatchQueue(label: "com.ultimedia.UMRecentFilesV2.SearchCoordinator", qos: .userInitiated)

	public init() {}

	deinit {
		stopSearch()
	}

	// MARK: - Public Search Controls

	/// Starts a background Spotlight metadata query for compatible document files.
	public func startSystemWideSearch(
		extensions: [String],
		excludeURLs: Set<URL> = [],
		limit: Int = 150
	) {
		stopSearch()
		clearDiscovered()

		guard !extensions.isEmpty else {
			searchStatusMessage = "No compatible document extensions defined."
			return
		}

		currentSearchTargetName = "Mac"
		isSearching = true
		searchStatusMessage = "Searching files with Spotlight..."

		let query = NSMetadataQuery()
		self.metadataQuery = query

		// Build Spotlight Predicate for matching extensions
		let subpredicates = extensions.map { ext in
			NSPredicate(format: "%K ==[cd] %@", NSMetadataItemFSNameKey, "*.\(ext)")
		}
		query.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
		query.searchScopes = [
			NSMetadataQueryUserHomeScope,
			NSMetadataQueryLocalComputerScope
		]
		query.sortDescriptors = [
			NSSortDescriptor(key: NSMetadataItemFSContentChangeDateKey, ascending: false)
		]

		// Observe live query updates and completion
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(metadataQueryDidUpdate(_:)),
			name: .NSMetadataQueryDidUpdate,
			object: query
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(metadataQueryDidFinishGathering(_:)),
			name: .NSMetadataQueryDidFinishGathering,
			object: query
		)

		query.start()
	}

	/// Recursively searches for matching files in a specified folder (e.g. external drives or user-chosen path).
	public func searchInFolder(
		folderURL: URL,
		extensions: [String],
		excludeURLs: Set<URL> = [],
		limit: Int = 200
	) {
		stopSearch()
		clearDiscovered()

		let normalizedExts = Set(extensions.map { $0.lowercased() })
		guard !normalizedExts.isEmpty else {
			searchStatusMessage = "No file extensions to search."
			return
		}

		currentSearchTargetName = folderURL.lastPathComponent
		isSearching = true
		searchStatusMessage = "Scanning \(folderURL.lastPathComponent)..."

		let workItem = DispatchWorkItem { [weak self] in
			guard let self = self else { return }

			let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey]
			let enumerator = FileManager.default.enumerator(
				at: folderURL,
				includingPropertiesForKeys: resourceKeys,
				options: [.skipsHiddenFiles, .skipsPackageDescendants]
			)

			var batch: [URL] = []
			var count = 0

			while let fileURL = enumerator?.nextObject() as? URL {
				if self.searchWorkItem?.isCancelled == true { break }

				let ext = fileURL.pathExtension.lowercased()
				if normalizedExts.contains(ext) && !excludeURLs.contains(fileURL) {
					batch.append(fileURL)
					count += 1

					if batch.count >= 15 {
						self.enqueueDiscoveredURLs(batch)
						batch.removeAll(keepingCapacity: true)
					}

					if count >= limit {
						break
					}
				}
			}

			if !batch.isEmpty {
				self.enqueueDiscoveredURLs(batch)
			}

			DispatchQueue.main.async {
				if self.searchWorkItem?.isCancelled == false {
					self.isSearching = false
					self.searchStatusMessage = "Finished. Found \(self.discoveredFiles.count) files."
				}
			}
		}

		self.searchWorkItem = workItem
		queue.async(execute: workItem)
	}

	/// Halts any active Spotlight query or directory scan.
	public func stopSearch() {
		if let query = metadataQuery {
			query.stop()
			query.disableUpdates()
			NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: query)
			NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: query)
			self.metadataQuery = nil
		}

		searchWorkItem?.cancel()
		searchWorkItem = nil

		flushTimer?.invalidate()
		flushTimer = nil

		DispatchQueue.main.async {
			self.isSearching = false
			if !self.discoveredFiles.isEmpty {
				self.searchStatusMessage = "\(self.discoveredFiles.count) files discovered."
			} else {
				self.searchStatusMessage = "Search stopped."
			}
		}
	}

	/// Removes a specific file from discovered results.
	public func removeDiscoveredFile(_ file: UMRecentFile) {
		discoveredFiles.removeAll(where: { $0.id == file.id || $0.url == file.url })
		discoveredURLsSet.remove(file.url)
	}

	/// Clears all currently discovered items.
	public func clearDiscovered() {
		discoveredFiles.removeAll()
		discoveredURLsSet.removeAll()
		pendingURLs.removeAll()
		searchStatusMessage = ""
	}

	// MARK: - Internal Batch Ingestion

	private func enqueueDiscoveredURLs(_ urls: [URL]) {
		DispatchQueue.main.async {
			var newFiles: [UMRecentFile] = []
			for url in urls {
				if !self.discoveredURLsSet.contains(url) {
					self.discoveredURLsSet.insert(url)
					newFiles.append(UMRecentFile(url: url))
				}
			}

			if !newFiles.isEmpty {
				self.discoveredFiles.append(contentsOf: newFiles)
				self.searchStatusMessage = "Found \(self.discoveredFiles.count) files..."
			}
		}
	}

	@objc private func metadataQueryDidUpdate(_ notification: Notification) {
		ingestMetadataQueryResults()
	}

	@objc private func metadataQueryDidFinishGathering(_ notification: Notification) {
		ingestMetadataQueryResults()
		DispatchQueue.main.async {
			self.isSearching = false
			self.searchStatusMessage = "Search complete. Found \(self.discoveredFiles.count) files."
		}
	}

	private func ingestMetadataQueryResults() {
		guard let query = metadataQuery else { return }
		query.disableUpdates()

		var newURLs: [URL] = []
		let count = query.resultCount
		let maxResults = min(count, 200)

		for i in 0..<maxResults {
			if let item = query.result(at: i) as? NSMetadataItem,
			   let path = item.value(forAttribute: NSMetadataItemPathKey) as? String {
				let url = URL(fileURLWithPath: path)
				if !self.discoveredURLsSet.contains(url) {
					newURLs.append(url)
				}
			}
		}

		query.enableUpdates()

		if !newURLs.isEmpty {
			enqueueDiscoveredURLs(newURLs)
		}
	}
}
