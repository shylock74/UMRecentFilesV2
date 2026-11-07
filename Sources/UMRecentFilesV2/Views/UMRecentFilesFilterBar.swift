//
//  UMRecentFilesFilterBar.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import SwiftUI
import UMUIControls

@available(macOS 12.0, *)
public struct UMRecentFilesFilterBar: View {

	@Binding public var searchText: String
	public let availableExtensions: [String]
	@Binding public var selectedExtension: String?

	public init(
		searchText: Binding<String>,
		availableExtensions: [String] = [],
		selectedExtension: Binding<String?>
	) {
		self._searchText = searchText
		self.availableExtensions = availableExtensions
		self._selectedExtension = selectedExtension
	}

	@Environment(\.umuiTheme) private var theme

	public var body: some View {
		VStack(spacing: 6) {
			// Search Input via UMUITextField
			HStack(spacing: 6) {
				UMUITextField(
					placeholder: "Search recent files...",
					value: $searchText,
					size: .small,
					isClearable: true
				)
			}
			.padding(.horizontal, 10)

			// Extension Filter Pills (when multiple types exist)
			if availableExtensions.count > 1 {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 6) {
						pillButton(title: "All", isSelected: selectedExtension == nil) {
							withAnimation(.easeInOut(duration: 0.15)) {
								selectedExtension = nil
							}
						}

						ForEach(availableExtensions, id: \.self) { ext in
							pillButton(title: ".\(ext)", isSelected: selectedExtension == ext) {
								withAnimation(.easeInOut(duration: 0.15)) {
									if selectedExtension == ext {
										selectedExtension = nil
									} else {
										selectedExtension = ext
									}
								}
							}
						}
					}
					.padding(.horizontal, 10)
					.padding(.bottom, 2)
				}
			}
		}
	}

	@ViewBuilder
	private func pillButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			Text(title)
				.font(.system(size: 10, weight: isSelected ? .bold : .medium))
				.foregroundColor(isSelected ? .white : theme.textSecondary)
				.padding(.horizontal, 8)
				.padding(.vertical, 3)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(isSelected ? theme.accentFill : theme.surfaceControl)
				)
		}
		.buttonStyle(.plain)
	}
}

