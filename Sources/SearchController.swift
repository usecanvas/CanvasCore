//
//  SearchController.swift
//  CanvasCore
//
//  Created by Sam Soffes on 12/2/15.
//  Copyright © 2015–2016 Canvas Labs, Inc. All rights reserved.
//

import Foundation
import CanvasKit

/// Object for coordinating searches
public final class SearchController: NSObject {

	// MARK: - Properties

	public let organizationID: String

	/// Results are delivered to this callback
	public var callback: (([Canvas]) -> Void)?

	fileprivate let semaphore = DispatchSemaphore(value: 0)

	fileprivate var nextQuery: String? {
		didSet {
			query()
		}
	}

	fileprivate let client: APIClient


	// MARK: - Initializers

	public init(client: APIClient, organizationID: String) {
		self.client = client
		self.organizationID = organizationID

		super.init()

		semaphore.signal()
	}


	// MARK: - Search

	public func search(withQuery query: String) {
		nextQuery = query.isEmpty ? nil : query
	}


	// MARK: - Private

	fileprivate func query() {
		guard nextQuery != nil else { return }

		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			guard let semaphore = self?.semaphore else { return }

			_ = semaphore.wait(timeout: DispatchTime.distantFuture)

			guard let query = self?.nextQuery,
				let client = self?.client,
				let organizationID = self?.organizationID
			else {
				semaphore.signal()
				return
			}

			self?.nextQuery = nil

			let callback = self?.callback

			client.searchCanvases(organizationID: organizationID, query: query) { result in
				DispatchQueue.main.async {
					switch result {
					case .success(let canvases): callback?(canvases)
					default: break
					}
				}

				semaphore.signal()
			}
		}
	}
}


#if !os(OSX)
	import UIKit

	extension SearchController: UISearchResultsUpdating {
		public func updateSearchResults(for searchController: UISearchController) {
			guard let text = searchController.searchBar.text else { return }
			search(withQuery: text)
		}
	}
#endif
