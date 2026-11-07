//
//  UMRecentFilesConfiguration.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import Foundation

/// Defines how UMRecentFiles retrieves and synchronizes documents.
public enum UMRecentFilesSourceMode: String, Codable, CaseIterable, Sendable {
	/// Synchronizes UserDefaults stored files with system recent documents (NSDocumentController).
	case hybrid
	/// Uses only the custom UserDefaults list (ideal for custom project categories or workflows).
	case customOnly
	/// Mirrors only the system recent documents from NSDocumentController.
	case systemOnly
}

/// Defines available sort orders for the recent files collection.
public enum UMRecentFilesSortOrder: String, Codable, CaseIterable, Sendable {
	/// Ordered by when the file was last opened in the app.
	case lastOpened
	/// Ordered by file modification date on disk.
	case dateModified
	/// Ordered alphabetically by file name (A-Z).
	case name
	/// Ordered by file size (largest to smallest).
	case size

	public var displayName: String {
		switch self {
		case .lastOpened: return "Recently Opened"
		case .dateModified: return "Date Modified"
		case .name: return "Name"
		case .size: return "Size"
		}
	}
}

/// Defines the display layout in the recent files user interface.
public enum UMRecentFilesViewLayout: String, Codable, CaseIterable, Sendable {
	case list
	case grid

	public var systemIcon: String {
		switch self {
		case .list: return "list.bullet"
		case .grid: return "square.grid.2x2"
		}
	}
}
