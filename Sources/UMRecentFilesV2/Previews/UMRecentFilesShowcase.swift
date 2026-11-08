//
//  UMRecentFilesShowcase.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import SwiftUI
import AppKit
import UMUIControls

#if DEBUG
@available(macOS 12.0, *)
public struct UMRecentFilesShowcaseView: View {

	@StateObject private var mockManager: UMRecentFiles

	public init() {
		let mgr = UMRecentFiles("UMRecentFilesMockPreview", sourceMode: .customOnly)
		mgr.fileList = Self.generateMockFiles()
		self._mockManager = StateObject(wrappedValue: mgr)
	}

	public var body: some View {
		VStack(spacing: 20) {
			Text("UMRecentFilesV2 Interactive Showcase")
				.font(.title2.bold())
				.foregroundColor(.primary)

			HStack(alignment: .top, spacing: 20) {
				// Embedded Widget in Sidebar Style
				VStack(alignment: .leading, spacing: 8) {
					Text("Embedded View (Sidebar / Inspector)")
						.font(.caption.bold())
						.foregroundColor(.secondary)

					UMRecentFilesView(
						manager: mockManager,
						title: "Recent Projects",
						manualURL: URL(string: "https://ulti.media/help"),
						callback: { url in
							print("Clicked mock file: \(url.lastPathComponent)")
						}
					)
					.frame(width: 320)
				}

				// Direct Open Recent Panel Preview
				VStack(alignment: .leading, spacing: 8) {
					Text("Open Recent Modal Window Panel")
						.font(.caption.bold())
						.foregroundColor(.secondary)

					UMOpenRecentPanelView(
						heroTitle: "Ulti.Media Studio",
						heroSubtitle: "Version 2.0 (Build 42)",
						manualURL: URL(string: "https://ulti.media/help"),
						filterExtensions: ["mp4", "wav", "fcpxml", "pdf"],
						manager: mockManager,
						createNewCallback: {
							print("Create new document")
						},
						selectedFileCallback: { url in
							print("Selected: \(url.path)")
						}
					)
					.clipShape(RoundedRectangle(cornerRadius: 10))
					.overlay(
						RoundedRectangle(cornerRadius: 10)
							.stroke(Color.secondary.opacity(0.2), lineWidth: 1)
					)
				}
			}
		}
		.padding(24)
		.umuiTheme(.proDark)
		.frame(minWidth: 1040, minHeight: 520)
	}

	private static func generateMockFiles() -> [UMRecentFile] {
		let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/tmp")

		return [
			UMRecentFile(
				name: "Commercial_Edit_Final_v3.mp4",
				url: docs.appendingPathComponent("Commercial_Edit_Final_v3.mp4"),
				lastOpenedDate: Date(),
				isPinned: true
			),
			UMRecentFile(
				name: "Podcast_Interview_Master.wav",
				url: docs.appendingPathComponent("Podcast_Interview_Master.wav"),
				lastOpenedDate: Date().addingTimeInterval(-3600),
				isPinned: true
			),
			UMRecentFile(
				name: "BeatMark_Project_Timeline.fcpxml",
				url: docs.appendingPathComponent("BeatMark_Project_Timeline.fcpxml"),
				lastOpenedDate: Date().addingTimeInterval(-86400 * 2),
				isPinned: false
			),
			UMRecentFile(
				name: "Client_Feedback_Notes.pdf",
				url: docs.appendingPathComponent("Client_Feedback_Notes.pdf"),
				lastOpenedDate: Date().addingTimeInterval(-86400 * 5),
				isPinned: false
			),
			UMRecentFile(
				name: "Soundtrack_Cue_Sheet.txt",
				url: docs.appendingPathComponent("Soundtrack_Cue_Sheet.txt"),
				lastOpenedDate: Date().addingTimeInterval(-86400 * 7),
				isPinned: false
			)
		]
	}
}

@available(macOS 12.0, *)
struct UMRecentFilesShowcaseView_Previews: PreviewProvider {
	static var previews: some View {
		UMRecentFilesShowcaseView()
	}
}
#endif

