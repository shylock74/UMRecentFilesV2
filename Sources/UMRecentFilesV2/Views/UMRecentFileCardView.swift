//
//  UMRecentFileCardView.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import SwiftUI
import AppKit
import UMUIControls

@available(macOS 12.0, *)
public struct UMRecentFileCardView: View {

	public let file: UMRecentFile
	public let removeExtension: Bool
	public let onSelect: (URL) -> Void
	public let onTogglePin: (UMRecentFile) -> Void
	public let onRemove: (UMRecentFile) -> Void

	@State private var isHovering = false
	@State private var thumbnail: NSImage?

	@Environment(\.umuiTheme) private var theme

	public init(
		file: UMRecentFile,
		removeExtension: Bool = false,
		onSelect: @escaping (URL) -> Void,
		onTogglePin: @escaping (UMRecentFile) -> Void,
		onRemove: @escaping (UMRecentFile) -> Void
	) {
		self.file = file
		self.removeExtension = removeExtension
		self.onSelect = onSelect
		self.onTogglePin = onTogglePin
		self.onRemove = onRemove
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			// Card Preview Area
			ZStack(alignment: .topTrailing) {
				RoundedRectangle(cornerRadius: 6)
					.fill(theme.surfaceRaised)
					.frame(height: 72)
					.overlay(
						Group {
							if let img = thumbnail {
								Image(nsImage: img)
									.resizable()
									.aspectRatio(contentMode: .fit)
									.padding(4)
							} else {
								Image(nsImage: NSWorkspace.shared.icon(forFile: file.url.path))
									.resizable()
									.aspectRatio(contentMode: .fit)
									.frame(width: 40, height: 40)
							}
						}
					)

				// Top Actions Overlay (Pin and Close)
				HStack(spacing: 2) {
					if file.isPinned || isHovering {
						Button {
							onTogglePin(file)
						} label: {
							Image(systemName: file.isPinned ? "pin.fill" : "pin")
								.font(.system(size: 9))
								.foregroundColor(file.isPinned ? theme.stateHero : theme.textSecondary)
								.padding(4)
								.background(theme.surfacePanel.opacity(0.85))
								.clipShape(Circle())
						}
						.buttonStyle(.plain)
					}

					if isHovering {
						Button {
							onRemove(file)
						} label: {
							Image(systemName: "xmark")
								.font(.system(size: 8, weight: .bold))
								.foregroundColor(theme.textTertiary)
								.padding(4)
								.background(theme.surfacePanel.opacity(0.85))
								.clipShape(Circle())
						}
						.buttonStyle(.plain)
					}
				}
				.padding(4)
			}

			// File Name & Details
			VStack(alignment: .leading, spacing: 2) {
				Text(removeExtension ? file.displayNameWithoutExtension : file.name)
					.font(theme.captionFont)
					.fontWeight(.semibold)
					.foregroundColor(file.existsOnDisk ? theme.textPrimary : theme.textDisabled)
					.lineLimit(1)
					.truncationMode(.middle)

				HStack(spacing: 4) {
					if let size = file.formattedFileSize {
						Text(size)
					}
					if let date = file.formattedModificationDate {
						Text("•")
						Text(date)
					}
				}
				.font(.system(size: 9))
				.foregroundColor(theme.textTertiary)
				.lineLimit(1)
			}
			.padding(.horizontal, 2)
		}
		.padding(6)
		.background(
			RoundedRectangle(cornerRadius: 8)
				.fill(isHovering ? theme.surfaceHover : theme.surfaceControl.opacity(0.6))
		)
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(file.isPinned ? theme.stateHero.opacity(0.4) : theme.strokeSubtle, lineWidth: 1)
		)
		.contentShape(Rectangle())
		.onHover { hovering in
			withAnimation(.easeInOut(duration: 0.1)) {
				isHovering = hovering
			}
		}
		.onTapGesture {
			onSelect(file.url)
		}
		.onDrag {
			NSItemProvider(object: file.url as NSURL)
		}
		.onAppear {
			loadThumbnail()
		}
	}

	private func loadThumbnail() {
		UMRecentThumbnailLoader.shared.loadThumbnail(for: file.url, size: CGSize(width: 120, height: 90)) { image in
			Task { @MainActor in
				self.thumbnail = image
			}
		}
	}
}
