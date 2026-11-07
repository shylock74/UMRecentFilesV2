//
//  UMDiskSearchControls.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import SwiftUI
import AppKit
import UMUIControls

@available(macOS 12.0, *)
public struct UMDiskSearchButton: View {

	@ObservedObject public var searchCoordinator: UMFileSearchCoordinator
	public let extensionsToSearch: [String]
	public var onFileSelected: ((URL) -> Void)?

	@Environment(\.umuiTheme) private var theme

	public init(
		searchCoordinator: UMFileSearchCoordinator,
		extensionsToSearch: [String],
		onFileSelected: ((URL) -> Void)? = nil
	) {
		self.searchCoordinator = searchCoordinator
		self.extensionsToSearch = extensionsToSearch
		self.onFileSelected = onFileSelected
	}

	public var body: some View {
		Menu {
			Button {
				searchCoordinator.startSystemWideSearch(extensions: extensionsToSearch)
			} label: {
				Label("Search Mac (Spotlight)", systemImage: "sparkle.magnifyingglass")
			}

			Button {
				chooseFolderAndSearch()
			} label: {
				Label("Search Specific Folder...", systemImage: "folder.badge.gearshape")
			}

			if searchCoordinator.isSearching {
				Divider()
				Button(role: .destructive) {
					searchCoordinator.stopSearch()
				} label: {
					Label("Stop Current Search", systemImage: "stop.circle")
				}
			}
		} label: {
			HStack(spacing: 4) {
				if searchCoordinator.isSearching {
					ProgressView()
						.scaleEffect(0.5)
						.frame(width: 14, height: 14)
				} else {
					Image(systemName: "internaldrive")
						.font(.system(size: 11, weight: .medium))
						.foregroundColor(theme.textSecondary)
				}
			}
			.frame(width: 22, height: 22)
			.background(theme.surfaceControl)
			.clipShape(RoundedRectangle(cornerRadius: 4))
		}
		.menuStyle(.borderlessButton)
		.frame(width: 22, height: 22)
		.help("Find compatible documents on disk...")
	}

	private func chooseFolderAndSearch() {
		let panel = NSOpenPanel()
		panel.canChooseFiles = false
		panel.canChooseDirectories = true
		panel.allowsMultipleSelection = false
		panel.prompt = "Search Folder"

		if panel.runModal() == .OK, let folder = panel.url {
			searchCoordinator.searchInFolder(folderURL: folder, extensions: extensionsToSearch)
		}
	}
}

// MARK: - Search Progress Pill
@available(macOS 12.0, *)
public struct UMSearchProgressPill: View {

	@ObservedObject public var searchCoordinator: UMFileSearchCoordinator

	@Environment(\.umuiTheme) private var theme

	public init(searchCoordinator: UMFileSearchCoordinator) {
		self.searchCoordinator = searchCoordinator
	}

	public var body: some View {
		HStack(spacing: 6) {
			if searchCoordinator.isSearching {
				ProgressView()
					.scaleEffect(0.55)
					.frame(width: 12, height: 12)
			} else {
				Image(systemName: "checkmark.circle.fill")
					.font(.system(size: 10))
					.foregroundColor(theme.stateForced)
			}

			Text(searchCoordinator.searchStatusMessage)
				.font(.system(size: 10, weight: .medium))
				.foregroundColor(theme.textSecondary)
				.lineLimit(1)

			Spacer(minLength: 4)

			if searchCoordinator.isSearching {
				Button {
					searchCoordinator.stopSearch()
				} label: {
					Image(systemName: "xmark.circle.fill")
						.font(.system(size: 11))
						.foregroundColor(theme.textTertiary)
				}
				.buttonStyle(.plain)
				.help("Stop search")
			} else {
				Button {
					searchCoordinator.clearDiscovered()
				} label: {
					Text("Clear")
						.font(.system(size: 9, weight: .semibold))
						.foregroundColor(theme.textTertiary)
				}
				.buttonStyle(.plain)
			}
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
		.background(theme.surfaceRaised)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
}
