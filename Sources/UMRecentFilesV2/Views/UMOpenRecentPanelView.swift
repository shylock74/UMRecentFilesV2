//
//  UMOpenRecentPanelView.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import SwiftUI
import AppKit
import UMUIControls

/// Full Open Recent window / panel view.
/// Replaces the legacy AppKit UMOpenRecentVC and UMOpenRecentWindow.storyboard with a pure SwiftUI implementation.
@available(macOS 12.0, *)
public struct UMOpenRecentPanelView: View {

	public let heroImage: NSImage?
	public let heroTitle: String
	public let heroSubtitle: String?
	public let manualURL: URL?
	public let removeExtension: Bool
	public let createNewCallback: (() -> Void)?
	public let selectedFileCallback: ((URL) -> Void)?
	public let deleteFileCallback: ((URL) -> Void)?
	public let onCancel: (() -> Void)?

	@ObservedObject public var manager: UMRecentFiles
	@StateObject private var searchCoordinator = UMFileSearchCoordinator()

	public let filterExtensions: [String]
	@State private var selectedTab: Int = 0 // 0 = Recent, 1 = On Disk
	@State private var searchText: String = ""
	@State private var selectedExtension: String? = nil
	@State private var layout: UMRecentFilesViewLayout = .list
	@State private var sortOrder: UMRecentFilesSortOrder = .lastOpened

	@Environment(\.umuiTheme) private var theme

	public init(
		heroImage: NSImage? = nil,
		heroTitle: String = "Open Recent",
		heroSubtitle: String? = nil,
		manualURL: URL? = nil,
		removeExtension: Bool = true,
		filterExtensions: [String] = [],
		manager: UMRecentFiles = UMRecentFiles.shared,
		createNewCallback: (() -> Void)? = nil,
		selectedFileCallback: ((URL) -> Void)? = nil,
		deleteFileCallback: ((URL) -> Void)? = nil,
		onCancel: (() -> Void)? = nil
	) {
		self.heroImage = heroImage
		self.heroTitle = heroTitle
		self.heroSubtitle = heroSubtitle
		self.manualURL = manualURL
		self.removeExtension = removeExtension
		self.filterExtensions = filterExtensions
		self.manager = manager
		self.createNewCallback = createNewCallback
		self.selectedFileCallback = selectedFileCallback
		self.deleteFileCallback = deleteFileCallback
		self.onCancel = onCancel
	}

	private var activeExtensions: [String] {
		UMAppDocumentTypes.resolveExtensions(
			explicitExtensions: filterExtensions,
			fallbackFromFiles: manager.fileList
		)
	}

	private var displayedRecentFiles: [UMRecentFile] {
		var exts: [String] = []
		if let ext = selectedExtension {
			exts = [ext]
		}
		return manager.filteredFiles(
			filterExtensions: exts,
			searchText: searchText,
			sortOrder: sortOrder,
			hideMissingFiles: false
		)
	}

	private var displayedDiscoveredFiles: [UMRecentFile] {
		var list = searchCoordinator.discoveredFiles

		if let ext = selectedExtension {
			list = list.filter { $0.fileExtension == ext.lowercased() }
		}

		if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			list = list.filter {
				UMRecentFileHelpers.searchContains(source: $0.name, query: searchText) ||
				UMRecentFileHelpers.searchContains(source: $0.url.path, query: searchText)
			}
		}

		return list
	}

	public var body: some View {
		HStack(spacing: 0) {
			// Left Column: Hero branding & primary actions
			VStack(spacing: 16) {
				// Hero Image
				if let img = heroImage ?? NSApp.applicationIconImage {
					Image(nsImage: img)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 80, height: 80)
						.shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
				}

				VStack(spacing: 4) {
					Text(heroTitle)
						.font(.system(size: 18, weight: .bold))
						.foregroundColor(theme.textPrimary)

					if let subtitle = heroSubtitle {
						Text(subtitle)
							.font(theme.captionFont)
							.foregroundColor(theme.textTertiary)
					}
				}

				Spacer()

				// Action Buttons
				VStack(spacing: 10) {
					if let createNew = createNewCallback {
						UMUICapsuleButton("Create New...", style: .accent, size: .normal) {
							createNew()
						}
					}

					UMUICapsuleButton("Open Other...", style: .gray, size: .normal) {
						let panel = NSOpenPanel()
						panel.canChooseFiles = true
						panel.canChooseDirectories = false
						panel.allowsMultipleSelection = false
						if panel.runModal() == .OK, let url = panel.url {
							manager.addFile(url: url)
							selectedFileCallback?(url)
						}
					}

					// Find on Disk Action Button
					UMUICapsuleButton(searchCoordinator.isSearching ? "Searching..." : "Find on Disk", style: .gray, size: .normal) {
						searchCoordinator.startSystemWideSearch(extensions: activeExtensions)
						selectedTab = 1
					}

					// Optional User Manual Action Button
					if let manual = manualURL {
						UMUICapsuleButton("User Manual", style: .gray, size: .normal) {
							NSWorkspace.shared.open(manual)
						}
					}

					if let cancel = onCancel {
						Button("Cancel") {
							cancel()
						}
						.buttonStyle(.plain)
						.font(theme.footnoteFont)
						.foregroundColor(theme.textTertiary)
						.padding(.top, 4)
					}
				}
				.frame(maxWidth: 160)
			}
			.padding(24)
			.frame(width: 220)
			.background(theme.surfacePanel)

			Divider()

			// Right Column: Recent Files Browser
			VStack(spacing: 10) {
				// Top search and controls
				HStack(spacing: 8) {
					UMUITextField(
						placeholder: "Search files...",
						value: $searchText,
						size: .small,
						isClearable: true
					)

					UMDiskSearchButton(
						searchCoordinator: searchCoordinator,
						extensionsToSearch: activeExtensions
					)

					Button {
						layout = (layout == .list) ? .grid : .list
					} label: {
						Image(systemName: layout == .list ? "square.grid.2x2" : "list.bullet")
							.font(.system(size: 11))
							.foregroundColor(theme.textSecondary)
							.frame(width: 24, height: 24)
							.background(theme.surfaceControl)
							.clipShape(RoundedRectangle(cornerRadius: 4))
					}
					.buttonStyle(.plain)
				}
				.padding(.horizontal, 14)
				.padding(.top, 14)

				// Search Progress Pill (if searching or found)
				if searchCoordinator.isSearching || !searchCoordinator.discoveredFiles.isEmpty {
					UMSearchProgressPill(searchCoordinator: searchCoordinator)
						.padding(.horizontal, 14)
				}

				// Mode Selector Tabs (when disk search is active or has results)
				if !searchCoordinator.discoveredFiles.isEmpty || searchCoordinator.isSearching {
					HStack(spacing: 0) {
						tabButton(title: "Recent (\(displayedRecentFiles.count))", index: 0)
						tabButton(title: "On Disk (\(displayedDiscoveredFiles.count))", index: 1)
					}
					.padding(.horizontal, 14)
				}

				let currentItems = (selectedTab == 1) ? displayedDiscoveredFiles : displayedRecentFiles

				// Files List / Grid Area
				if currentItems.isEmpty {
					UMUIEmptyStateView(
						systemImage: selectedTab == 1 ? "internaldrive" : "clock.badge.questionmark",
						title: selectedTab == 1 ? "No Compatible Files Found" : "No Recent Files Found",
						message: selectedTab == 1 ? "Use 'Find on Disk' or choose a folder to discover documents." : (searchText.isEmpty ? "No recent items in history." : "No files matching \"\(searchText)\".")
					)
				} else {
					ScrollView {
						if layout == .list {
							LazyVStack(spacing: 2) {
								ForEach(currentItems) { file in
									UMRecentFileRowView(
										file: file,
										removeExtension: removeExtension,
										showThumbnail: true,
										onSelect: { url in
											manager.addFile(url: url)
											selectedFileCallback?(url)
										},
										onTogglePin: { manager.togglePin($0) },
										onRemove: { file in
											if selectedTab == 1 {
												searchCoordinator.removeDiscoveredFile(file)
											} else {
												deleteFileCallback?(file.url)
												manager.removeRecentFile(file)
											}
										}
									)
								}
							}
							.padding(.horizontal, 12)
						} else {
							LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
								ForEach(currentItems) { file in
									UMRecentFileCardView(
										file: file,
										removeExtension: removeExtension,
										onSelect: { url in
											manager.addFile(url: url)
											selectedFileCallback?(url)
										},
										onTogglePin: { manager.togglePin($0) },
										onRemove: { file in
											if selectedTab == 1 {
												searchCoordinator.removeDiscoveredFile(file)
											} else {
												deleteFileCallback?(file.url)
												manager.removeRecentFile(file)
											}
										}
									)
								}
							}
							.padding(.horizontal, 14)
						}
					}
				}

				// Small summary footer when finished searching on disk
				if selectedTab == 1 && !searchCoordinator.isSearching && !searchCoordinator.discoveredFiles.isEmpty {
					HStack {
						Image(systemName: "internaldrive")
							.font(.system(size: 9))
						Text("\(displayedDiscoveredFiles.count) files found on disk")
							.font(.system(size: 10))
						Spacer()
					}
					.foregroundColor(theme.textTertiary)
					.padding(.horizontal, 14)
					.padding(.bottom, 4)
				}
			}
			.frame(minWidth: 420, maxWidth: .infinity)
			.background(theme.surfaceWindow)
		}
		.frame(width: 680, height: 420)
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
}

// MARK: - AppKit Window Presentation Bridge (Retrocompatible with UMOpenRecentVC / UMOpenRecent)
public enum UMOpenRecent {

	private static var currentWindowController: NSWindowController?

	/// Shows a dedicated modal/window for Open Recent, retrocompatible with legacy UMOmniaFramework.
	public static func showWindow(
		image: NSImage? = nil,
		fileIcon: NSImage? = nil,
		manualURL: URL? = nil,
		removeExtension: Bool = true,
		createNewCallback: (() -> Void)? = nil,
		selectedFileCallback: ((URL) -> Void)? = nil,
		deleteFileCallback: ((URL) -> Void)? = nil
	) {
		let closeWindow: () -> Void = {
			currentWindowController?.close()
			currentWindowController = nil
		}

		let panelView = UMOpenRecentPanelView(
			heroImage: image,
			heroTitle: "Open Recent",
			manualURL: manualURL,
			removeExtension: removeExtension,
			createNewCallback: {
				closeWindow()
				createNewCallback?()
			},
			selectedFileCallback: { url in
				closeWindow()
				selectedFileCallback?(url)
			},
			deleteFileCallback: deleteFileCallback,
			onCancel: {
				closeWindow()
			}
		)

		let hostingController = NSHostingController(rootView: panelView)
		let window = NSWindow(contentViewController: hostingController)
		window.title = "Open Recent"
		window.styleMask = [.titled, .closable, .miniaturizable]
		window.isReleasedWhenClosed = false
		window.center()

		let controller = NSWindowController(window: window)
		self.currentWindowController = controller
		controller.showWindow(nil)
		NSApp.activate(ignoringOtherApps: true)
	}
}

/// Backwards compatibility alias for UMOpenRecentVC
public typealias UMOpenRecentVC = UMOpenRecent
