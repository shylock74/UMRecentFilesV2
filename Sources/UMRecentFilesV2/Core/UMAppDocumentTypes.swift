//
//  UMAppDocumentTypes.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import Foundation
import UniformTypeIdentifiers

/// Utilities to discover file extensions and uniform types supported by the host application.
public enum UMAppDocumentTypes {

	/// Returns all document file extensions declared in the host app's Info.plist (`CFBundleDocumentTypes`).
	public static func detectedExtensions() -> [String] {
		var extensions: Set<String> = []

		if let docTypes = Bundle.main.infoDictionary?["CFBundleDocumentTypes"] as? [[String: Any]] {
			for typeDict in docTypes {
				if let exts = typeDict["CFBundleTypeExtensions"] as? [String] {
					for ext in exts {
						let clean = ext.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ". "))
						if !clean.isEmpty {
							extensions.insert(clean)
						}
					}
				}
			}
		}

		return Array(extensions).sorted()
	}

	/// Returns all document content types declared in the host app's Info.plist (`CFBundleDocumentTypes`).
	@available(macOS 11.0, *)
	public static func detectedContentTypes() -> [UTType] {
		var types: [UTType] = []

		if let docTypes = Bundle.main.infoDictionary?["CFBundleDocumentTypes"] as? [[String: Any]] {
			for typeDict in docTypes {
				if let typeIdentifiers = typeDict["LSItemContentTypes"] as? [String] {
					for identifier in typeIdentifiers {
						if let utType = UTType(identifier) {
							types.append(utType)
						}
					}
				}
			}
		}

		return types
	}

	/// Resolves extensions to search for: explicit extensions > Info.plist declared > fallback.
	public static func resolveExtensions(
		explicitExtensions: [String],
		fallbackFromFiles: [UMRecentFile] = []
	) -> [String] {
		let cleanedExplicit = explicitExtensions
			.map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ". ")) }
			.filter { !$0.isEmpty }

		if !cleanedExplicit.isEmpty {
			return cleanedExplicit
		}

		let detected = detectedExtensions()
		if !detected.isEmpty {
			return detected
		}

		let fallbackSet = Set(fallbackFromFiles.map { $0.fileExtension }.filter { !$0.isEmpty })
		return Array(fallbackSet).sorted()
	}
}

