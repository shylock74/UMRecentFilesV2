//
//  UMRecentFilesMenu.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import SwiftUI
import AppKit

/// A ready-to-use SwiftUI Menu component for recent files.
@available(macOS 12.0, *)
public struct UMRecentFilesMenu: View {

	public let title: String
	public let filterExtensions: [String]
	public let onSelect: (URL) -> Void
	@ObservedObject public var manager: UMRecentFiles

	public init(
		title: String = "Open Recent",
		filterExtensions: [String] = [],
		manager: UMRecentFiles = UMRecentFiles.shared,
		onSelect: @escaping (URL) -> Void
	) {
		self.title = title
		self.filterExtensions = filterExtensions
		self.manager = manager
		self.onSelect = onSelect
	}

	private var validFiles: [UMRecentFile] {
		manager.filteredFiles(
			filterExtensions: filterExtensions,
			searchText: "",
			sortOrder: .lastOpened,
			hideMissingFiles: true
		)
	}

	public var body: some View {
		Menu(title) {
			if validFiles.isEmpty {
				Text("No Recent Files")
			} else {
				let pinned = validFiles.filter { $0.isPinned }
				let unpinned = validFiles.filter { !$0.isPinned }

				if !pinned.isEmpty {
					Section("Pinned") {
						ForEach(pinned) { file in
							Button {
								onSelect(file.url)
							} label: {
								Label(file.name, systemImage: "pin.fill")
							}
						}
					}
				}

				if !unpinned.isEmpty {
					Section {
						ForEach(unpinned) { file in
							Button {
								onSelect(file.url)
							} label: {
								Text(file.name)
							}
						}
					}
				}

				Divider()

				Button("Clear Menu") {
					manager.clearAll(keepPinned: true)
				}
			}
		}
	}
}
