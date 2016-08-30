//
//  AccountController.swift
//  CanvasCore
//
//  Created by Sam Soffes on 11/3/15.
//  Copyright © 2015–2016 Canvas Labs, Inc. All rights reserved.
//

import CanvasKit
import SAMKeychain

open class AccountController {

	// MARK: - Properties

	open var currentAccount: Account? {
		didSet {
			if let account = currentAccount, let data = try? JSONSerialization.data(withJSONObject: account.dictionary, options: []) {
				SAMKeychain.setPasswordData(data, forService: "Canvas", account: "Account")
			} else {
				_ = SAMKeychain.deletePassword(forService: "Canvas", account: "Account")
				UserDefaults.standard.removeObject(forKey: "Organizations")
				UserDefaults.standard.removeObject(forKey: "SelectedOrganization")
			}

			NotificationCenter.default.post(name: type(of: self).accountDidChangeNotification, object: nil)
		}
	}

	open static let accountDidChangeNotification: NSNotification.Name = NSNotification.Name(rawValue: "AccountController.accountDidChangeNotification")

	open static let sharedController = AccountController()


	// MARK: - Initializers

	init() {
		guard let data = SAMKeychain.passwordData(forService: "Canvas", account: "Account") else { return }

		guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
			let dictionary = json as? JSONDictionary,
			let account = Account(dictionary: dictionary)
		else {
			_ = SAMKeychain.deletePassword(forService: "Canvas", account: "Account")
			return
		}

		currentAccount = account
	}
}
