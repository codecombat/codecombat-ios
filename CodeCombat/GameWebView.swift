//
//  GameWebView.swift
//  CodeCombat
//
//  Created by Sam Soffes on 10/15/15.
//  Copyright © 2015 CodeCombat. All rights reserved.
//

import UIKit
import WebKit

class GameWebView: WKWebView {

	// MARK: - Properties

	var user: User? {
		didSet {
			guard let user = user  else { return }
			
			let loginScript = [
				"function __signIn() {",
				"  if(me.get('anonymous') && !me.get('iosIdentifierForVendor')) {",
				"    require('core/auth').loginUser({'email':'\(user.email)','password':'\(user.password)'});",
				"  }",
				"}",
				"setTimeout(__signIn, 1000);"
			].joinWithSeparator("\n")

			let userScript = WKUserScript(source: loginScript, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
			configuration.userContentController.addUserScript(userScript)

			if let URL = NSURL(string: "/play", relativeToURL: rootURL) {
				loadRequest(NSURLRequest(URL: URL))
			}
		}
	}

	private(set) var currentFragment: String?

	let notificationCenter = NSNotificationCenter()


	// MARK: - Initializers

	override init(frame: CGRect, configuration: WKWebViewConfiguration) {
		super.init(frame: frame, configuration: configuration)

		backgroundColor = Color.darkBrown
		scrollView.scrollEnabled = false

		// TODO: Hookup user script to forward events to notification center

		notificationCenter.addObserver(self, selector: "didReceiveJavaScriptError:", name: "application:error", object: nil)
		notificationCenter.addObserver(self, selector: "didNavigate:", name: "router:navigated", object: nil)
	}

	deinit {
		notificationCenter.removeObserver(self)
	}


	// MARK: - Notifications

	@objc private func didReceiveJavaScriptError(notification: NSNotification) {
		guard let message = notification.userInfo?["message"] as? String else { return }
		print("💔💔💔 Unhandled JS error in application: \(message)")
	}

	@objc private func didNavigate(notification: NSNotification) {
//		currentFragment = notification.userInfo?["route"] as? String
	}
}

