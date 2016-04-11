//
//  APIClient.swift
//  CodeCombat
//
//  Created by Sam Soffes on 10/8/15.
//  Copyright © 2015 CodeCombat. All rights reserved.
//

import Foundation

/// Generic API result.
enum APIResult<T> {
	/// The request succeed and has an associated generic value.
	case Success(T)

	/// The request failed and has an associated error string.
	case Failure(String)
}


/// Client for communicating with the API.
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

	/// Sign in with a username and password.
	func signIn(username username: String, password: String, completion: APIResult<User> -> Void) {
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
			if error != nil {
				completion(.Failure("Failed to sign in. (-1)"))
				return
			}

			guard let data = data, JSON = try? NSJSONSerialization.JSONObjectWithData(data, options: []) else {
				completion(.Failure("Failed to sign in. (-2)"))
				return
			}

			if let userJSON = JSON as? [String: AnyObject], user = User(dictionary: userJSON, password: password) {
				completion(.Success(user))
				return
			}

			// TODO: /auth/login error responses changed 2016-04-11, so this may need updating. 
			if let errors = JSON as? [[String: String]], property = errors.first?["property"] {
				if property == "password" {
					completion(.Failure("The password for your account is incorrect."))
				} else if property == "email" {
					completion(.Failure("We couldn't find an account for that email."))
				} else {
					completion(.Failure("Your credentials are incorrect."))
				}
				return
			}

			completion(.Failure("Failed to sign in. (-3)"))
		}.resume()
	}
}
