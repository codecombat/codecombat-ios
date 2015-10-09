import Foundation

private let sharedUserInstance = User()

class User {
	var name: String?
	var email: String?
	var password: String?
	var rawData: [String: AnyObject]?

	init() {}

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

	class var sharedInstance: User {
		return sharedUserInstance
	}

	class func randomPassword() -> String {
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
