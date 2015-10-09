//
//  APIClient.swift
//  CodeCombat
//
//  Created by Sam Soffes on 10/8/15.
//  Copyright © 2015 CodeCombat. All rights reserved.
//

import Foundation

enum APIResult<T> {
	case Success(T)
	case Failure(String)
}

class APIClient {

	// MARK: - Properties

	let baseURL: NSURL
	private let session: NSURLSession


	// MARK: - Initializers

	init(baseURL: NSURL = rootURL, session: NSURLSession = NSURLSession.sharedSession()) {
		self.baseURL = baseURL
		self.session = session
	}


	// MARK: - Requests

	func performLoginRequest(username username: String, password: String, completion: APIResult<User> -> Void) {
		guard let URL = NSURL(string: "/auth/login", relativeToURL: baseURL) else {
			return
		}

		let credentials = [
			"username": username,
			"password": password
		]

		let request = NSMutableURLRequest(URL: URL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 5.0)
		request.HTTPMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(credentials, options: [])

		session.dataTaskWithRequest(request) { data, _, error in
			if let error = error {
//				let errorObject:AnyObject = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
//				let ErrorDictionaries = errorObject as? [[String:String]]
//				if ErrorDictionaries![0]["property"] == "password" {
//				errorMessage = NSLocalizedString("The password for your account is incorrect.", comment:"")
//				} else if ErrorDictionaries![0]["property"] == "email" {
//				errorMessage = NSLocalizedString("We couldn't find an account for that email.", comment:"")
//				} else {
//				errorMessage = NSLocalizedString("Your credentials are incorrect.", comment:"")
//				}
//				}
				completion(.Failure("Failed to sign in."))
				return
			}

			guard let data = data,
				JSON = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
				userJSON = JSON as? [String: AnyObject],
				user = User(dictionary: userJSON, password: password)
			else {
				completion(.Failure("Failed to deserialize user JSON."))
				return
			}

//			User.sharedInstance = user
//			WebManager.sharedInstance.authCookieIsFresh = true

			completion(.Success(user))
		}.resume()
	}
}
