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

			let script: String

			if user.isAnonymous {
				script = [
					"function __signInAnonymous() {",
					"  me.set('iosIdentifierForVendor','\(user.username)');",
					"  me.set('password','\(user.password)'); me.save();",
					"}",
					"if (!me.get('iosIdentifierForVendor') && me.get('anonymous')) {",
					"  setTimeout(__signInAnonymous, 1);",
					"}"
				].joinWithSeparator("\n")
			} else {
				script = [
					"function __signIn() {",
					"  if(me.get('anonymous') && !me.get('iosIdentifierForVendor')) {",
					"    require('core/auth').loginUser({'email':'\(user.username)','password':'\(user.password)'});",
					"  }",
					"}",
					"setTimeout(__signIn, 1000);"
				].joinWithSeparator("\n")
			}

			let userScript = WKUserScript(source: script, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
			configuration.userContentController.addUserScript(userScript)

			if let URL = NSURL(string: "/play", relativeToURL: rootURL) {
				loadRequest(NSURLRequest(URL: URL))
			}
		}
	}

	private(set) var currentFragment: String?


	// MARK: - Initializers

	override init(frame: CGRect, configuration: WKWebViewConfiguration) {
		super.init(frame: frame, configuration: configuration)

		backgroundColor = Color.darkBrown
		scrollView.scrollEnabled = false

		configuration.userContentController.addScriptMessageHandler(self, name: "notification")
	}
}


extension GameWebView: WKScriptMessageHandler {
	func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		guard let body = message.body as? [String: AnyObject], name = body["name"] as? String else { return }

		if name == "signOut" {
			User.currentUser = nil
		}
	}
}
