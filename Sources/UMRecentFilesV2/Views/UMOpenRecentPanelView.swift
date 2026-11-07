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
	public let removeExtension: Bool
	public let createNewCallback: (() -> Void)?
	public let selectedFileCallback: ((URL) -> Void)?
	public let deleteFileCallback: ((URL) -> Void)?
	public let onCancel: (() -> Void)?

	@ObservedObject public var manager: UMRecentFiles

	@State private var searchText: String = ""
	@State private var selectedExtension: String? = nil
	@State private var layout: UMRecentFilesViewLayout = .list
	@State private var sortOrder: UMRecentFilesSortOrder = .lastOpened

	@Environment(\.umuiTheme) private var theme

	public init(
		heroImage: NSImage? = nil,
		heroTitle: String = "Open Recent",
		heroSubtitle: String? = nil,
		removeExtension: Bool = true,
		manager: UMRecentFiles = UMRecentFiles.shared,
		createNewCallback: (() -> Void)? = nil,
		selectedFileCallback: ((URL) -> Void)? = nil,
		deleteFileCallback: ((URL) -> Void)? = nil,
		onCancel: (() -> Void)? = nil
	) {
		self.heroImage = heroImage
		self.heroTitle = heroTitle
		self.heroSubtitle = heroSubtitle
		self.removeExtension = removeExtension
		self.manager = manager
		self.createNewCallback = createNewCallback
		self.selectedFileCallback = selectedFileCallback
		self.deleteFileCallback = deleteFileCallback
		self.onCancel = onCancel
	}

	private var displayedFiles: [UMRecentFile] {
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
						placeholder: "Search recent files...",
						value: $searchText,
						size: .small,
						isClearable: true
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

				// Files List / Grid Area
				if displayedFiles.isEmpty {
					UMUIEmptyStateView(
						systemImage: "clock.badge.questionmark",
						title: "No Recent Files Found",
						message: searchText.isEmpty ? "No recent items in history." : "No files matching \"\(searchText)\"."
					)
				} else {
					ScrollView {
						if layout == .list {
							LazyVStack(spacing: 2) {
								ForEach(displayedFiles) { file in
									UMRecentFileRowView(
										file: file,
										removeExtension: removeExtension,
										showThumbnail: true,
										onSelect: { url in selectedFileCallback?(url) },
										onTogglePin: { manager.togglePin($0) },
										onRemove: { file in
											deleteFileCallback?(file.url)
											manager.removeRecentFile(file)
										}
									)
								}
							}
							.padding(.horizontal, 12)
						} else {
							LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
								ForEach(displayedFiles) { file in
									UMRecentFileCardView(
										file: file,
										removeExtension: removeExtension,
										onSelect: { url in selectedFileCallback?(url) },
										onTogglePin: { manager.togglePin($0) },
										onRemove: { file in
											deleteFileCallback?(file.url)
											manager.removeRecentFile(file)
										}
									)
								}
							}
							.padding(.horizontal, 14)
						}
					}
				}
			}
			.frame(minWidth: 420, maxWidth: .infinity)
			.background(theme.surfaceWindow)
		}
		.frame(width: 680, height: 420)
	}
}

// MARK: - AppKit Window Presentation Bridge (Retrocompatible with UMOpenRecentVC / UMOpenRecent)
public enum UMOpenRecent {

	private static var currentWindowController: NSWindowController?

	/// Shows a dedicated modal/window for Open Recent, retrocompatible with legacy UMOmniaFramework.
	public static func showWindow(
		image: NSImage? = nil,
		fileIcon: NSImage? = nil,
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
