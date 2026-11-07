//
//  UMRecentFileRowView.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import SwiftUI
import AppKit
import UMUIControls

@available(macOS 12.0, *)
public struct UMRecentFileRowView: View {

	public let file: UMRecentFile
	public let removeExtension: Bool
	public let showThumbnail: Bool
	public let onSelect: (URL) -> Void
	public let onTogglePin: (UMRecentFile) -> Void
	public let onRemove: (UMRecentFile) -> Void

	@State private var isHovering = false
	@State private var isTapped = false
	@State private var thumbnail: NSImage?

	@Environment(\.umuiTheme) private var theme

	public init(
		file: UMRecentFile,
		removeExtension: Bool = false,
		showThumbnail: Bool = true,
		onSelect: @escaping (URL) -> Void,
		onTogglePin: @escaping (UMRecentFile) -> Void,
		onRemove: @escaping (UMRecentFile) -> Void
	) {
		self.file = file
		self.removeExtension = removeExtension
		self.showThumbnail = showThumbnail
		self.onSelect = onSelect
		self.onTogglePin = onTogglePin
		self.onRemove = onRemove
	}

	public var body: some View {
		HStack(spacing: 8) {
			// Thumbnail / Icon with Pin indicator
			ZStack(alignment: .topLeading) {
				if let img = thumbnail {
					Image(nsImage: img)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 26, height: 26)
						.clipShape(RoundedRectangle(cornerRadius: 4))
				} else {
					Image(nsImage: NSWorkspace.shared.icon(forFile: file.url.path))
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 26, height: 26)
				}

				if file.isPinned {
					Image(systemName: "pin.fill")
						.font(.system(size: 7))
						.foregroundColor(theme.stateHero)
						.padding(2)
						.background(theme.surfacePanel.opacity(0.85))
						.clipShape(Circle())
						.offset(x: -3, y: -3)
				}
			}
			.frame(width: 28, height: 28)

			// File Name & Path Details
			VStack(alignment: .leading, spacing: 2) {
				HStack(spacing: 4) {
					Text(removeExtension ? file.displayNameWithoutExtension : file.name)
						.font(theme.bodyFont)
						.fontWeight(.medium)
						.foregroundColor(file.existsOnDisk ? theme.textPrimary : theme.textDisabled)
						.lineLimit(1)
						.truncationMode(.middle)

					if !file.existsOnDisk {
						Text("Missing")
							.font(.system(size: 9, weight: .bold))
							.foregroundColor(theme.destructive)
							.padding(.horizontal, 4)
							.padding(.vertical, 1)
							.background(theme.destructive.opacity(0.15))
							.clipShape(Capsule())
					}
				}

				HStack(spacing: 5) {
					Text(file.abbreviatedPath)
						.lineLimit(1)
						.truncationMode(.head)

					if let size = file.formattedFileSize {
						Text("•")
						Text(size)
					}

					if let date = file.formattedModificationDate {
						Text("•")
						Text(date)
					}
				}
				.font(theme.captionFont)
				.foregroundColor(theme.textTertiary)
			}

			Spacer(minLength: 4)

			// Trailing Loading Spinner or Quick Hover Actions
			if isTapped {
				ProgressView()
					.scaleEffect(0.6)
					.frame(width: 20, height: 20)
			} else if isHovering {
				HStack(spacing: 2) {
					// Pin / Unpin Button
					Button {
						onTogglePin(file)
					} label: {
						Image(systemName: file.isPinned ? "pin.slash.fill" : "pin.fill")
							.font(.system(size: 10))
							.foregroundColor(file.isPinned ? theme.stateHero : theme.textSecondary)
							.frame(width: 20, height: 20)
					}
					.buttonStyle(.plain)
					.help(file.isPinned ? "Unpin from top" : "Pin to top")

					// Reveal in Finder Button
					Button {
						file.url.showInFinder()
					} label: {
						Image(systemName: "folder")
							.font(.system(size: 10))
							.foregroundColor(theme.textSecondary)
							.frame(width: 20, height: 20)
					}
					.buttonStyle(.plain)
					.help("Show in Finder")

					// Remove from Recent Files Button
					Button {
						onRemove(file)
					} label: {
						Image(systemName: "xmark")
							.font(.system(size: 9, weight: .bold))
							.foregroundColor(theme.textTertiary)
							.frame(width: 20, height: 20)
					}
					.buttonStyle(.plain)
					.help("Remove from recents")
				}
				.transition(.opacity)
			}
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 5)
		.background(
			RoundedRectangle(cornerRadius: 6)
				.fill(rowBackgroundColor)
		)
		.contentShape(Rectangle())
		.onHover { hovering in
			withAnimation(.easeInOut(duration: 0.1)) {
				isHovering = hovering
			}
		}
		.onTapGesture {
			guard file.existsOnDisk else {
				file.url.showInFinder()
				return
			}
			isTapped = true
			onSelect(file.url)
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
				isTapped = false
			}
		}
		.onDrag {
			NSItemProvider(object: file.url as NSURL)
		}
		.contextMenu {
			Button {
				onSelect(file.url)
			} label: {
				Label("Open", systemImage: "arrow.up.right")
			}

			Button {
				onTogglePin(file)
			} label: {
				Label(file.isPinned ? "Unpin from Top" : "Pin to Top", systemImage: file.isPinned ? "pin.slash" : "pin")
			}

			Button {
				file.url.showInFinder()
			} label: {
				Label("Show in Finder", systemImage: "folder")
			}

			Divider()

			Button {
				NSPasteboard.general.clearContents()
				NSPasteboard.general.setString(file.url.path, forType: .string)
			} label: {
				Label("Copy Path", systemImage: "doc.on.doc")
			}

			Button {
				NSPasteboard.general.clearContents()
				NSPasteboard.general.setString(file.name, forType: .string)
			} label: {
				Label("Copy File Name", systemImage: "doc.on.clipboard")
			}

			Divider()

			Button(role: .destructive) {
				onRemove(file)
			} label: {
				Label("Remove from Recents", systemImage: "trash")
			}
		}
		.onAppear {
			loadThumbnailIfNeeded()
		}
	}

	private var rowBackgroundColor: Color {
		if isTapped {
			return theme.accentSubtle
		} else if isHovering {
			return theme.surfaceHover
		} else if file.isPinned {
			return theme.surfaceRaised.opacity(0.5)
		} else {
			return Color.clear
		}
	}

	private func loadThumbnailIfNeeded() {
		guard showThumbnail else { return }
		UMRecentThumbnailLoader.shared.loadThumbnail(for: file.url, size: CGSize(width: 56, height: 56)) { image in
			Task { @MainActor in
				self.thumbnail = image
			}
		}
	}
}
