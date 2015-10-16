import UIKit

struct User {

	// MARK: - Properties

	var username: String
	var password: String

	var isAnonymous: Bool {
		return !username.containsString("@")
	}


	// MARK: - Initializers

	init(username: String, password: String) {
		self.username = username
		self.password = password
	}

	init?(dictionary: [String: AnyObject], password: String) {
		guard let username = dictionary["username"] as? String else { return nil }

		self.username = username
		self.password = password
	}

	init?(credential: NSURLCredential) {
		guard let username = credential.user,
			password = credential.password
		else {
			return nil
		}

		self.username = username
		self.password = password
	}


	// MARK: - Static

	static let currentUserDidChangeNotificationName = "User.currentUserDidChangeNotification"

	static var currentUser: User? = {
		guard let protectionSpace = protectionSpace,
			credential = NSURLCredentialStorage.sharedCredentialStorage().defaultCredentialForProtectionSpace(protectionSpace)
		else { return nil }

		return User(credential: credential)
	}() {
		willSet {
			let storage = NSURLCredentialStorage.sharedCredentialStorage()
			guard let user = currentUser,
				protectionSpace = protectionSpace,
				credentials = storage.credentialsForProtectionSpace(protectionSpace)
			else { return }

			for (username, credential) in credentials {
				if username == user.username {
					storage.removeCredential(credential, forProtectionSpace: protectionSpace)
				}
			}
		}

		didSet {
			if let user = currentUser, protectionSpace = protectionSpace {
				NSURLCredentialStorage.sharedCredentialStorage().setCredential(user.credential, forProtectionSpace: protectionSpace)
			}

			dispatch_async(dispatch_get_main_queue()) {
				NSNotificationCenter.defaultCenter().postNotificationName(currentUserDidChangeNotificationName, object: nil)
			}
		}
	}

	static func anonymousUser() -> User? {
		guard let username = UIDevice.currentDevice().identifierForVendor?.UUIDString else { return nil }
		return User(username: username, password: randomPassword())
	}


	// MARK: - Private

	private var credential: NSURLCredential {
		return NSURLCredential(user: username, password: password, persistence: .Permanent)
	}

	private static let protectionSpace: NSURLProtectionSpace? = {
		guard let host = rootURL.host, port = rootURL.port?.integerValue else { return nil }
		return NSURLProtectionSpace(host: host, port: port, `protocol`: rootURL.scheme, realm: nil, authenticationMethod: nil)
	}()

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
