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
			let loginScript = "" +
"function __signIn() {" +
"  if(me.get('anonymous') && !me.get('iosIdentifierForVendor')) {" +
"    require('core/auth').loginUser({'email':'\(user.email)','password':'\(user.password)'});" +
"  }" +
"}" +
"setTimeout(__signIn, 1000);"

			let userScript = WKUserScript(source: loginScript, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
			configuration.userContentController.addUserScript(userScript)

			if let URL = NSURL(string: "/play", relativeToURL: rootURL) {
				loadRequest(NSURLRequest(URL: URL))
			}
		}
	}


	// MARK: - Initializers

	override init(frame: CGRect, configuration: WKWebViewConfiguration) {
		super.init(frame: frame, configuration: configuration)

		backgroundColor = Color.darkBrown
		scrollView.scrollEnabled = false
	}
}

