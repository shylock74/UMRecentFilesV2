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
	@StateObject private var searchCoordinator = UMFileSearchCoordinator()

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

	@State private var selectedTab: Int = 0 // 0 = Recent, 1 = On Disk
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
		UMAppDocumentTypes.resolveExtensions(
			explicitExtensions: filterExtensions,
			fallbackFromFiles: manager.fileList
		)
	}

	private var displayedRecentFiles: [UMRecentFile] {
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

	private var displayedDiscoveredFiles: [UMRecentFile] {
		var list = searchCoordinator.discoveredFiles

		if let selectedExt = selectedExtension {
			list = list.filter { $0.fileExtension == selectedExt.lowercased() }
		}

		if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			list = list.filter {
				UMRecentFileHelpers.searchContains(source: $0.name, query: searchText) ||
				UMRecentFileHelpers.searchContains(source: $0.url.path, query: searchText)
			}
		}

		return list
	}

	// MARK: - View Body
	public var body: some View {
		VStack(spacing: 0) {
			// Header Row
			UMRecentFilesHeaderView(
				isOpen: $isOpen,
				title: title,
				count: displayedRecentFiles.count,
				allowLayoutSwitch: allowLayoutSwitch,
				allowSorting: allowSorting,
				extensionsToSearch: activeExtensions,
				searchCoordinator: searchCoordinator,
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

					// Active Search Status Pill (if searching or files found)
					if searchCoordinator.isSearching || !searchCoordinator.discoveredFiles.isEmpty {
						UMSearchProgressPill(searchCoordinator: searchCoordinator)
							.padding(.horizontal, 10)
							.transition(.opacity)
					}

					// Mode Selector Tabs (when disk search has results or is searching)
					if !searchCoordinator.discoveredFiles.isEmpty || searchCoordinator.isSearching {
						HStack(spacing: 0) {
							tabButton(title: "Recent (\(displayedRecentFiles.count))", index: 0)
							tabButton(title: "On Disk (\(displayedDiscoveredFiles.count))", index: 1)
						}
						.padding(.horizontal, 10)
						.padding(.top, 2)
					}

					// Main List / Grid Content
					let currentItems = (selectedTab == 1) ? displayedDiscoveredFiles : displayedRecentFiles

					if currentItems.isEmpty {
						UMUIEmptyStateView(
							systemImage: selectedTab == 1 ? "internaldrive" : "doc.badge.gearshape",
							title: selectedTab == 1 ? "No Compatible Files Found" : "No Recent Files",
							message: selectedTab == 1 ? "Search with Spotlight or choose a specific folder above." : "Opened documents will appear here automatically."
						)
						.frame(height: 120)
					} else {
						contentScrollView(items: currentItems, isDiscovered: selectedTab == 1)
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
	private func tabButton(title: String, index: Int) -> some View {
		Button {
			withAnimation(.easeInOut(duration: 0.15)) {
				selectedTab = index
			}
		} label: {
			Text(title)
				.font(.system(size: 11, weight: selectedTab == index ? .bold : .medium))
				.foregroundColor(selectedTab == index ? theme.textPrimary : theme.textTertiary)
				.padding(.vertical, 4)
				.frame(maxWidth: .infinity)
				.background(
					selectedTab == index ? theme.surfaceControl : Color.clear
				)
				.clipShape(RoundedRectangle(cornerRadius: 6))
		}
		.buttonStyle(.plain)
	}

	@ViewBuilder
	private func contentScrollView(items: [UMRecentFile], isDiscovered: Bool) -> some View {
		ScrollView {
			if currentLayout.wrappedValue == .list {
				LazyVStack(spacing: 2) {
					ForEach(items) { file in
						UMRecentFileRowView(
							file: file,
							removeExtension: removeExtension,
							showThumbnail: showThumbnails,
							onSelect: handleFileSelection,
							onTogglePin: { manager.togglePin($0) },
							onRemove: { fileToRemove in
								if isDiscovered {
									searchCoordinator.removeDiscoveredFile(fileToRemove)
								} else {
									manager.removeRecentFile(fileToRemove)
								}
							}
						)
					}
				}
				.padding(.horizontal, 6)
			} else {
				LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 6)], spacing: 6) {
					ForEach(items) { file in
						UMRecentFileCardView(
							file: file,
							removeExtension: removeExtension,
							onSelect: handleFileSelection,
							onTogglePin: { manager.togglePin($0) },
							onRemove: { fileToRemove in
								if isDiscovered {
									searchCoordinator.removeDiscoveredFile(fileToRemove)
								} else {
									manager.removeRecentFile(fileToRemove)
								}
							}
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

