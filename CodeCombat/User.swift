import UIKit

struct User {
	var name: String?
	var email: String
	var password: String
	var rawData: [String: AnyObject]?

	init(email: String, password: String) {
		self.email = email
		self.password = password
	}

	init?(dictionary: [String: AnyObject], password: String) {
		guard let name = dictionary["name"] as? String,
			email = dictionary["email"] as? String
		else {
			return nil
		}

		self.name = name
		self.email = email
		self.password = password
		rawData = dictionary
	}

	static var currentUser: User?

	static func anonymousUser() -> User? {
		guard let username = UIDevice.currentDevice().identifierForVendor?.UUIDString else { return nil }
		return User(email: username, password: randomPassword())
	}

	private static func randomPassword() -> String {
		let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789!@#$%^&*()90"
		let charactersLength = UInt32(characters.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))

		var password = ""

		for _ in 0..<25 {
			let random = Int(arc4random_uniform(charactersLength))
			password += String(characters[characters.startIndex.advancedBy(random)])
		}

		return password
	}
}
