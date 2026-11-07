//
//  UMRecentFilesHeaderView.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import SwiftUI
import UMUIControls

@available(macOS 12.0, *)
public struct UMRecentFilesHeaderView: View {

	@Binding public var isOpen: Bool
	public let title: String
	public let count: Int
	public let allowLayoutSwitch: Bool
	public let allowSorting: Bool
	@Binding public var layout: UMRecentFilesViewLayout
	@Binding public var sortOrder: UMRecentFilesSortOrder
	public var onClearRequested: (() -> Void)?

	public init(
		isOpen: Binding<Bool>,
		title: String = "Recent Files",
		count: Int,
		allowLayoutSwitch: Bool = true,
		allowSorting: Bool = true,
		layout: Binding<UMRecentFilesViewLayout>,
		sortOrder: Binding<UMRecentFilesSortOrder>,
		onClearRequested: (() -> Void)? = nil
	) {
		self._isOpen = isOpen
		self.title = title
		self.count = count
		self.allowLayoutSwitch = allowLayoutSwitch
		self.allowSorting = allowSorting
		self._layout = layout
		self._sortOrder = sortOrder
		self.onClearRequested = onClearRequested
	}

	@Environment(\.umuiTheme) private var theme

	public var body: some View {
		HStack(spacing: 8) {
			// Fold / Unfold trigger button
			Button {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
					isOpen.toggle()
				}
			} label: {
				HStack(spacing: 6) {
					Image(systemName: "clock")
						.font(.system(size: 13, weight: .semibold))
						.foregroundColor(theme.accentText)

					Text(title)
						.font(theme.headlineFont)
						.foregroundColor(theme.textPrimary)

					if count > 0 {
						Text("\(count)")
							.font(.system(size: 10, weight: .bold))
							.foregroundColor(theme.textSecondary)
							.padding(.horizontal, 6)
							.padding(.vertical, 2)
							.background(theme.surfaceRaised)
							.clipShape(Capsule())
					}

					Image(systemName: "chevron.right")
						.font(.system(size: 9, weight: .bold))
						.foregroundColor(theme.textTertiary)
						.rotationEffect(isOpen ? .degrees(90) : .degrees(0))
				}
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)

			Spacer(minLength: 4)

			// Contextual controls visible when open
			if isOpen {
				HStack(spacing: 4) {
					// Layout Toggle Button
					if allowLayoutSwitch {
						Button {
							withAnimation(.easeInOut(duration: 0.15)) {
								layout = (layout == .list) ? .grid : .list
							}
						} label: {
							Image(systemName: layout == .list ? "square.grid.2x2" : "list.bullet")
								.font(.system(size: 11, weight: .medium))
								.foregroundColor(theme.textSecondary)
								.frame(width: 22, height: 22)
								.background(theme.surfaceControl)
								.clipShape(RoundedRectangle(cornerRadius: 4))
						}
						.buttonStyle(.plain)
						.help(layout == .list ? "Switch to Grid View" : "Switch to List View")
					}

					// Sorting and Actions Menu
					if allowSorting {
						Menu {
							Section("Sort By") {
								ForEach(UMRecentFilesSortOrder.allCases, id: \.self) { order in
									Button {
										sortOrder = order
									} label: {
										HStack {
											Text(order.displayName)
											if sortOrder == order {
												Image(systemName: "checkmark")
											}
										}
									}
								}
							}

							if let onClear = onClearRequested {
								Divider()
								Button(role: .destructive, action: onClear) {
									Label("Clear Recent Files", systemImage: "trash")
								}
							}
						} label: {
							Image(systemName: "arrow.up.arrow.down")
								.font(.system(size: 11, weight: .medium))
								.foregroundColor(theme.textSecondary)
								.frame(width: 22, height: 22)
								.background(theme.surfaceControl)
								.clipShape(RoundedRectangle(cornerRadius: 4))
						}
						.menuStyle(.borderlessButton)
						.frame(width: 22, height: 22)
						.help("Sort options")
					}
				}
				.transition(.opacity)
			}
		}
		.padding(.horizontal, 10)
		.padding(.vertical, 8)
		.background(theme.surfacePanel.opacity(0.8))
	}
}

