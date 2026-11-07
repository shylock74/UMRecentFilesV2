//
//  UMRecentFile.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import Foundation

/// Represents a single recent document or file entry.
/// Fully compatible with JSON persisted by legacy UMOmniaFramework / UMFoundation versions.
public class UMRecentFile: Codable, Identifiable, Hashable, Equatable, @unchecked Sendable {

	// MARK: - Stored / Codable Properties
	public var id: String
	public var name: String
	public var url: URL
	public var lastOpenedDate: Date
	public var isPinned: Bool
	public var bookmarkData: Data?

	// MARK: - Initializer
	public init(
		name: String? = nil,
		url: URL,
		id: String = UUID().uuidString,
		lastOpenedDate: Date = Date(),
		isPinned: Bool = false,
		bookmarkData: Data? = nil
	) {
		self.id = id
		self.url = url
		self.name = (name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
			? name!
			: url.lastPathComponent
		self.lastOpenedDate = lastOpenedDate
		self.isPinned = isPinned
		self.bookmarkData = bookmarkData ?? UMRecentFileHelpers.createSecurityBookmark(for: url)
	}

	// MARK: - Retrocompatible Codable Implementation
	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case url
		case lastOpenedDate
		case isPinned
		case bookmarkData
	}

	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString

		// URL fallback
		if let decodedURL = try? container.decodeIfPresent(URL.self, forKey: .url) {
			self.url = decodedURL
		} else {
			self.url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/")
		}

		// Name fallback
		if let decodedName = try? container.decodeIfPresent(String.self, forKey: .name), !decodedName.isEmpty {
			self.name = decodedName
		} else {
			self.name = self.url.lastPathComponent
		}

		self.lastOpenedDate = (try? container.decodeIfPresent(Date.self, forKey: .lastOpenedDate)) ?? Date()
		self.isPinned = (try? container.decodeIfPresent(Bool.self, forKey: .isPinned)) ?? false
		self.bookmarkData = try? container.decodeIfPresent(Data.self, forKey: .bookmarkData)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(name, forKey: .name)
		try container.encode(url, forKey: .url)
		try container.encode(lastOpenedDate, forKey: .lastOpenedDate)
		try container.encode(isPinned, forKey: .isPinned)
		try container.encodeIfPresent(bookmarkData, forKey: .bookmarkData)
	}

	// MARK: - Dynamic Metadata Helpers
	public var existsOnDisk: Bool {
		url.existsOnDisk
	}

	public var fileSize: Int64? {
		url.fileSizeOnDisk
	}

	public var formattedFileSize: String? {
		guard let size = fileSize else { return nil }
		return UMRecentFileHelpers.formatFileSize(size)
	}

	public var modificationDate: Date? {
		url.modificationDateOnDisk
	}

	public var formattedModificationDate: String? {
		guard let date = modificationDate else { return nil }
		return UMRecentFileHelpers.formatDate(date)
	}

	public var fileExtension: String {
		url.pathExtension.lowercased()
	}

	public var parentFolderName: String {
		url.deletingLastPathComponent().lastPathComponent
	}

	public var abbreviatedPath: String {
		UMRecentFileHelpers.abbreviatePath(url.deletingLastPathComponent().path)
	}

	public var displayNameWithoutExtension: String {
		url.deletingPathExtension().lastPathComponent
	}

	// MARK: - Hashable & Equatable
	public static func == (lhs: UMRecentFile, rhs: UMRecentFile) -> Bool {
		lhs.id == rhs.id || lhs.url == rhs.url
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(url)
	}
}

