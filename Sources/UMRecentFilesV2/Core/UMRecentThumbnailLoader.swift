//
//  UMRecentThumbnailLoader.swift
//  UMRecentFilesV2
//
//  Created by Alex Raccuglia on 07/11/2026.
//

import AppKit
import QuickLookThumbnailing

/// Asynchronous thumbnail generator that uses QuickLook for rich previews
/// with automatic caching and graceful fallback to system file icons.
public final class UMRecentThumbnailLoader: @unchecked Sendable {

	public static let shared = UMRecentThumbnailLoader()

	private let cache = NSCache<NSURL, NSImage>()
	private let queue = DispatchQueue(label: "com.ultimedia.UMRecentFilesV2.ThumbnailLoader", qos: .userInitiated)

	private init() {
		cache.countLimit = 250
	}

	/// Returns a cached image immediately if available.
	public func cachedThumbnail(for url: URL) -> NSImage? {
		cache.object(forKey: url as NSURL)
	}

	/// Asynchronously loads a QuickLook thumbnail of the given size, or falls back to system file icon.
	public func loadThumbnail(
		for url: URL,
		size: CGSize = CGSize(width: 64, height: 64),
		completion: @escaping @Sendable (NSImage) -> Void
	) {
		let nsURL = url as NSURL
		if let cached = cache.object(forKey: nsURL) {
			DispatchQueue.main.async {
				completion(cached)
			}
			return
		}

		queue.async { [weak self] in
			guard let self = self else { return }

			let request = QLThumbnailGenerator.Request(
				fileAt: url,
				size: size,
				scale: NSScreen.main?.backingScaleFactor ?? 2.0,
				representationTypes: .thumbnail
			)

			QLThumbnailGenerator.shared.generateRepresentations(for: request) { representation, _, error in
				if let rep = representation, error == nil {
					let image = rep.nsImage
					self.cache.setObject(image, forKey: nsURL)
					DispatchQueue.main.async {
						completion(image)
					}
				} else {
					// Fallback to system file icon
					let icon = NSWorkspace.shared.icon(forFile: url.path)
					icon.size = size
					self.cache.setObject(icon, forKey: nsURL)
					DispatchQueue.main.async {
						completion(icon)
					}
				}
			}
		}
	}
}
