//
//  UMRecentFilesView.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import SwiftUI
import AppKit
import UMUIControls

/// Main expandable/foldable recent files view.
/// Fully backwards compatible with the legacy UMRecentFilesView signature from UMSwiftUI.
@available(macOS 12.0, *)
public struct UMRecentFilesView: View {

	// MARK: - Manager & Configuration
	@ObservedObject public var manager: UMRecentFiles

	public var title: String
	public var filterExtensions: [String]
	public var callback: ((URL) -> Void)?
	public var removeExtension: Bool
	public var showThumbnails: Bool
	public var allowLayoutSwitch: Bool
	public var allowSorting: Bool
	public var hideMissingFiles: Bool

	// MARK: - Local State
	@AppStorage("UMRecentFiles.isOpen") private var isOpen: Bool = false
	@AppStorage("UMRecentFiles.layout") private var layoutRaw: String = UMRecentFilesViewLayout.list.rawValue
	@AppStorage("UMRecentFiles.sortOrder") private var sortOrderRaw: String = UMRecentFilesSortOrder.lastOpened.rawValue

	@State private var searchText: String = ""
	@State private var selectedExtension: String? = nil
	@State private var isTargetedForDrop: Bool = false

	@Environment(\.umuiTheme) private var theme

	// MARK: - Initializer (Backwards Compatible with UMSwiftUI)
	public init(
		filterExtensions: [String] = [],
		callback: ((URL) -> Void)? = nil
	) {
		self.init(
			manager: UMRecentFiles.shared,
			title: "Recent Files",
			filterExtensions: filterExtensions,
			callback: callback
		)
	}

	// MARK: - Advanced Initializer
	public init(
		manager: UMRecentFiles = UMRecentFiles.shared,
		title: String = "Recent Files",
		filterExtensions: [String] = [],
		callback: ((URL) -> Void)?,
		removeExtension: Bool = false,
		showThumbnails: Bool = true,
		allowLayoutSwitch: Bool = true,
		allowSorting: Bool = true,
		hideMissingFiles: Bool = true
	) {
		self.manager = manager
		self.title = title
		self.filterExtensions = filterExtensions
		self.callback = callback
		self.removeExtension = removeExtension
		self.showThumbnails = showThumbnails
		self.allowLayoutSwitch = allowLayoutSwitch
		self.allowSorting = allowSorting
		self.hideMissingFiles = hideMissingFiles
	}

	// MARK: - Computed Properties
	private var currentLayout: Binding<UMRecentFilesViewLayout> {
		Binding(
			get: { UMRecentFilesViewLayout(rawValue: layoutRaw) ?? .list },
			set: { layoutRaw = $0.rawValue }
		)
	}

	private var currentSortOrder: Binding<UMRecentFilesSortOrder> {
		Binding(
			get: { UMRecentFilesSortOrder(rawValue: sortOrderRaw) ?? .lastOpened },
			set: { sortOrderRaw = $0.rawValue }
		)
	}

	private var activeExtensions: [String] {
		if !filterExtensions.isEmpty {
			return filterExtensions
		}
		// Discover distinct extensions in the current list
		let allExts = Set(manager.fileList.map { $0.fileExtension }.filter { !$0.isEmpty })
		return Array(allExts).sorted()
	}

	private var displayedFiles: [UMRecentFile] {
		var extensionsToFilter = filterExtensions
		if let selectedExt = selectedExtension {
			extensionsToFilter = [selectedExt]
		}

		return manager.filteredFiles(
			filterExtensions: extensionsToFilter,
			searchText: searchText,
			sortOrder: currentSortOrder.wrappedValue,
			hideMissingFiles: hideMissingFiles
		)
	}

	// MARK: - View Body
	public var body: some View {
		VStack(spacing: 0) {
			// Header Row
			UMRecentFilesHeaderView(
				isOpen: $isOpen,
				title: title,
				count: displayedFiles.count,
				allowLayoutSwitch: allowLayoutSwitch,
				allowSorting: allowSorting,
				layout: currentLayout,
				sortOrder: currentSortOrder,
				onClearRequested: {
					manager.clearAll(keepPinned: true)
				}
			)

			// Expandable Content
			if isOpen {
				VStack(spacing: 8) {
					// Filter & Search Bar
					UMRecentFilesFilterBar(
						searchText: $searchText,
						availableExtensions: activeExtensions,
						selectedExtension: $selectedExtension
					)
					.padding(.top, 6)

					// Main List / Grid
					if displayedFiles.isEmpty {
						UMUIEmptyStateView(
							systemImage: "doc.badge.gearshape",
							title: "No Recent Files",
							message: searchText.isEmpty ? "Opened documents will appear here automatically." : "No files matched \"\(searchText)\"."
						)
						.frame(height: 120)
					} else {
						contentScrollView
					}
				}
				.padding(.bottom, 6)
				.transition(.opacity)
			}
		}
		.background(theme.surfacePanel.opacity(0.5))
		.clipShape(RoundedRectangle(cornerRadius: 8))
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(isTargetedForDrop ? theme.accentFill : theme.strokeSubtle, lineWidth: isTargetedForDrop ? 1.5 : 1)
		)
		.onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
			handleDroppedFiles(providers)
		}
	}

	@ViewBuilder
	private var contentScrollView: some View {
		ScrollView {
			if currentLayout.wrappedValue == .list {
				LazyVStack(spacing: 2) {
					ForEach(displayedFiles) { file in
						UMRecentFileRowView(
							file: file,
							removeExtension: removeExtension,
							showThumbnail: showThumbnails,
							onSelect: handleFileSelection,
							onTogglePin: { manager.togglePin($0) },
							onRemove: { manager.removeRecentFile($0) }
						)
					}
				}
				.padding(.horizontal, 6)
			} else {
				LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 6)], spacing: 6) {
					ForEach(displayedFiles) { file in
						UMRecentFileCardView(
							file: file,
							removeExtension: removeExtension,
							onSelect: handleFileSelection,
							onTogglePin: { manager.togglePin($0) },
							onRemove: { manager.removeRecentFile($0) }
						)
					}
				}
				.padding(.horizontal, 8)
			}
		}
		.frame(maxHeight: 280)
	}

	// MARK: - Action Handlers
	private func handleFileSelection(url: URL) {
		manager.addFile(url: url)
		if let callback = callback {
			callback(url)
		} else {
			NSWorkspace.shared.open(url)
		}
	}

	private func handleDroppedFiles(_ providers: [NSItemProvider]) -> Bool {
		for provider in providers {
			_ = provider.loadObject(ofClass: URL.self) { url, _ in
				if let fileURL = url {
					DispatchQueue.main.async {
						manager.addFile(url: fileURL)
						handleFileSelection(url: fileURL)
					}
				}
			}
		}
		return true
	}
}

