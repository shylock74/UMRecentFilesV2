//
//  UMMacSearchField.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 17/11/2026.
//

import SwiftUI
import AppKit

/// Standard macOS `NSSearchField` wrapped for SwiftUI with integrated search glyph and clear button.
@available(macOS 12.0, *)
public struct UMMacSearchField: NSViewRepresentable {

	public let placeholder: String
	@Binding public var text: String
	public var controlSize: NSControl.ControlSize

	public init(
		placeholder: String = "Search...",
		text: Binding<String>,
		controlSize: NSControl.ControlSize = .small
	) {
		self.placeholder = placeholder
		self._text = text
		self.controlSize = controlSize
	}

	public func makeNSView(context: Context) -> NSSearchField {
		let searchField = NSSearchField()
		searchField.placeholderString = placeholder
		searchField.controlSize = controlSize
		searchField.sendsSearchStringImmediately = true
		searchField.sendsWholeSearchString = false
		searchField.isBezeled = true
		searchField.bezelStyle = .roundedBezel
		searchField.focusRingType = .default
		searchField.delegate = context.coordinator
		searchField.stringValue = text
		return searchField
	}

	public func updateNSView(_ nsView: NSSearchField, context: Context) {
		if nsView.stringValue != text {
			nsView.stringValue = text
		}
		if nsView.placeholderString != placeholder {
			nsView.placeholderString = placeholder
		}
		if nsView.controlSize != controlSize {
			nsView.controlSize = controlSize
		}
	}

	public func makeCoordinator() -> Coordinator {
		Coordinator(text: $text)
	}

	public final class Coordinator: NSObject, NSSearchFieldDelegate {
		@Binding private var text: String

		init(text: Binding<String>) {
			self._text = text
		}

		public func controlTextDidChange(_ obj: Notification) {
			guard let searchField = obj.object as? NSSearchField else { return }
			if text != searchField.stringValue {
				text = searchField.stringValue
			}
		}

		public func searchFieldDidEndSearching(_ sender: NSSearchField) {
			if text != sender.stringValue {
				text = sender.stringValue
			}
		}
	}
}
