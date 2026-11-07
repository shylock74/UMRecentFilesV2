//
//  UMRecentFileHelpers.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import Foundation
import AppKit

public enum UMRecentFileHelpers {

	/// Returns a human-readable file size string (e.g. "12.4 MB").
	public static func formatFileSize(_ bytes: Int64) -> String {
		let byteCountFormatter = ByteCountFormatter()
		byteCountFormatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
		byteCountFormatter.countStyle = .file
		return byteCountFormatter.string(fromByteCount: bytes)
	}

	/// Returns a concise formatted date string (e.g. "Today 14:30" or "07 Nov 14:30").
	public static func formatDate(_ date: Date) -> String {
		let calendar = Calendar.current
		let timeFormatter = DateFormatter()
		timeFormatter.dateFormat = "HH:mm"
		let timeString = timeFormatter.string(from: date)

		if calendar.isDateInToday(date) {
			return "Today \(timeString)"
		} else if calendar.isDateInYesterday(date) {
			return "Yesterday \(timeString)"
		} else {
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "dd MMM HH:mm"
			return dateFormatter.string(from: date)
		}
	}

	/// Abbreviates a full directory path (e.g. replaces the home directory with "~").
	public static func abbreviatePath(_ path: String) -> String {
		let home = NSHomeDirectory()
		if path.hasPrefix(home) {
			return "~" + path.dropFirst(home.count)
		}
		return path
	}

	/// Checks if a string contains a search query in a case-insensitive and diacritic-insensitive manner.
	public static func searchContains(source: String, query: String) -> Bool {
		let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return true }
		return source.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
	}

	/// Reveals a file in macOS Finder.
	public static func showInFinder(url: URL) {
		NSWorkspace.shared.activateFileViewerSelecting([url])
	}

	/// Creates a Security-Scoped Bookmark for persistent access across app launches and sandboxing.
	public static func createSecurityBookmark(for url: URL) -> Data? {
		#if os(macOS)
		return try? url.bookmarkData(
			options: .withSecurityScope,
			includingResourceValuesForKeys: nil,
			relativeTo: nil
		)
		#else
		return nil
		#endif
	}

	/// Resolves an existing Security-Scoped Bookmark into an active URL.
	public static func resolveSecurityBookmark(_ data: Data) -> URL? {
		#if os(macOS)
		var isStale = false
		let url = try? URL(
			resolvingBookmarkData: data,
			options: .withSecurityScope,
			relativeTo: nil,
			bookmarkDataIsStale: &isStale
		)
		return url
		#else
		return nil
		#endif
	}
}

// MARK: - Convenient Extensions
public extension URL {
	/// Convenience property to reveal file in Finder
	func showInFinder() {
		UMRecentFileHelpers.showInFinder(url: self)
	}

	/// Checks if the file or folder exists on disk
	var existsOnDisk: Bool {
		FileManager.default.fileExists(atPath: self.path)
	}

	/// Returns file size in bytes if available
	var fileSizeOnDisk: Int64? {
		guard let attributes = try? FileManager.default.attributesOfItem(atPath: self.path),
			  let size = attributes[.size] as? NSNumber else {
			return nil
		}
		return size.int64Value
	}

	/// Returns file modification date if available
	var modificationDateOnDisk: Date? {
		guard let attributes = try? FileManager.default.attributesOfItem(atPath: self.path),
			  let date = attributes[.modificationDate] as? Date else {
			return nil
		}
		return date
	}
}
