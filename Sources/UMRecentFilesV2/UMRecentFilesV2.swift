//
//  UMRecentFilesV2.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import Foundation
import SwiftUI
import AppKit

// Re-export UMUIControls so callers have seamless access to UMUITheme, buttons and fields
@_exported import UMUIControls

/// Root module helper for UMRecentFilesV2.
public struct UMRecentFilesV2 {

	public static let version = "2.0.3"

	public init() {}

	/// Opens a recent file at the given URL using the standard system handler.
	public static func openFile(_ url: URL) {
		NSWorkspace.shared.open(url)
	}

	/// Opens the application manual or website documentation.
	public static func openManual(url: URL) {
		NSWorkspace.shared.open(url)
	}

	/// Opens the modern SwiftUI "Open Recent" window.
	public static func showOpenRecentWindow(
		image: NSImage? = nil,
		manualURL: URL? = nil,
		removeExtension: Bool = true,
		createNewCallback: (() -> Void)? = nil,
		selectedFileCallback: ((URL) -> Void)? = nil,
		deleteFileCallback: ((URL) -> Void)? = nil
	) {
		UMOpenRecent.showWindow(
			image: image,
			manualURL: manualURL,
			removeExtension: removeExtension,
			createNewCallback: createNewCallback,
			selectedFileCallback: selectedFileCallback,
			deleteFileCallback: deleteFileCallback
		)
	}
}

// MARK: - Backward Compatibility Typealiases
public typealias UMRecentFilesV2Manager = UMRecentFiles
public typealias UMRecentFilesV2Item = UMRecentFile
public typealias UMRecentFilesV2View = UMRecentFilesView
