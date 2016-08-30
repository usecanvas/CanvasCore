//
//  AvatarsController.swift
//  CanvasCore
//
//  Created by Sam Soffes on 6/8/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import Cache
import X

public final class AvatarsController {

	// MARK: - Types

	public typealias Completion = (_ id: String, _ image: Image?) -> Void


	// MARK: - Properties

	public static let sharedController = AvatarsController()

	public let session: URLSession

	fileprivate var downloading = [String: [Completion]]()
	fileprivate let queue = DispatchQueue(label: "com.usecanvas.canvas.avatarscontroller")
	fileprivate let memoryCache = MemoryCache<Image>()
	fileprivate let imageCache: MultiCache<Image>
	fileprivate let placeholderCache = MemoryCache<Image>()


	// MARK: - Initializers

	public init(session: URLSession = URLSession.shared) {
		self.session = session

		var caches = [AnyCache(memoryCache)]

		// Setup disk cache
		if let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
			let directory = (cachesDirectory as NSString).appendingPathComponent("CanvasAvatars") as String

			if let diskCache = DiskCache<Image>(directory: directory) {
				caches.append(AnyCache(diskCache))
			}
		}

		imageCache = MultiCache(caches: caches)
	}


	// MARK: - Accessing

	public func fetchImage(id: String, url: URL, completion: Completion) -> Image? {
		if let image = memoryCache[id] {
			return image
		}

		imageCache.get(key: id) { [weak self] image in
			if let image = image {
				DispatchQueue.main.async {
					completion(id, image)
				}
				return
			}

			self?.queue.sync { [weak self] in
				// Already downloading
				if var array = self?.downloading[id] {
					array.append(completion)
					self?.downloading[id] = array
					return
				}

				// Start download
				self?.downloading[id] = [completion]

				let request = URLRequest(url: url)
				self?.session.downloadTask(with: request) { [weak self] location, _, _ in
					self?.loadImage(location: location, id: id)
				}.resume()
			}
		}

		return nil
	}


	// MARK: - Private

	fileprivate func loadImage(location: URL?, id: String) {
		let data = location.flatMap { try? Data(contentsOf: $0) }
		let image = data.flatMap { Image(data: $0 as Data) }

		if let image = image {
			imageCache.set(key: id, value: image)
		}

		queue.sync { [weak self] in
			if let image = image, let completions = self?.downloading[id] {
				for completion in completions {
					DispatchQueue.main.async {
						completion(id, image)
					}
				}
			}

			self?.downloading[id] = nil
		}
	}
}
