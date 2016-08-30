//
//  SessionDelegate.swift
//  CanvasCore
//
//  Created by Sam Soffes on 7/22/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import Foundation

/// Internal class for SSL pinning
final class SessionDelegate: NSObject, URLSessionDelegate {
	func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		guard let serverTrust = challenge.protectionSpace.serverTrust,
			let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
			let path = bundle.path(forResource: "STAR_usecanvas_com", ofType: "der"),
			let localCertificate = try? Data(contentsOf: URL(fileURLWithPath: path))
		else {
			completionHandler(.cancelAuthenticationChallenge, nil)
			return
		}

		// Set SSL policies for domain name check
		let policies = NSMutableArray()
		policies.add(SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString?)))
		SecTrustSetPolicies(serverTrust, policies);

		// Evaluate server certificate
		var result: SecTrustResultType = .unspecified
		SecTrustEvaluate(serverTrust, &result)
		let isServerTrusted = (result == .unspecified || result == .proceed)

		// Get local and remote cert data
		let remoteCertificateData:Data = SecCertificateCopyData(certificate) as Data

		if (isServerTrusted && (remoteCertificateData == localCertificate)) {
			let credential = URLCredential(trust: serverTrust)
			completionHandler(.useCredential, credential)
			return
		}

		completionHandler(.cancelAuthenticationChallenge, nil)
	}
}

let sessionDelegate = SessionDelegate()
