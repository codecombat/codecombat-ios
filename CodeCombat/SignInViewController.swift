//
//  SignInViewController.swift
//  iPadClient
//
//  Created by Sam Soffes on 10/7/15.
//  Copyright (c) 2015 CodeCombat. All rights reserved.
//

import UIKit

/// View controller that manages signing and signing up.
class SignInViewController: UIViewController {

	// Properties

	private let modal = SignInModalView()
	private var modalTopConstraint: NSLayoutConstraint!
	

	// MARK: - Initializers

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}


	// MARK: - UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()

		let background = SignInBackgroundView()
		background.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(background)

		modal.translatesAutoresizingMaskIntoConstraints = false
		modal.usernameTextField.delegate = self
		modal.passwordTextField.delegate = self
		modal.signInButton.addTarget(self, action: "signIn:", forControlEvents: .TouchUpInside)
		modal.signUpLaterButton.addTarget(self, action: "signUpLater:", forControlEvents: .TouchUpInside)
		view.addSubview(modal)

		modalTopConstraint = NSLayoutConstraint(item: modal, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 64)

		NSLayoutConstraint.activateConstraints([
			background.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
			background.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
			background.topAnchor.constraintEqualToAnchor(view.topAnchor),
			background.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),

			modal.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
			modalTopConstraint
		])

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
	}


	// MARK: - Actions

	@objc private func signIn(sender: AnyObject?) {
		guard let username = modal.usernameTextField.text,
			password = modal.passwordTextField.text
		where !username.isEmpty && !password.isEmpty
		else {
			showError("Please input a username and password.")
			return
		}

		modal.loading = true

		APIClient().signIn(username: username, password: password) { [weak self] result in
			switch result {
			case .Success(let user):
				WebManager.sharedInstance.authCookieIsFresh = true
				dispatch_async(dispatch_get_main_queue()) {
					// WebManager.sharedInstance.authCookieIsFresh = true
					User.currentUser = user
				}
			case .Failure(let message):
				dispatch_async(dispatch_get_main_queue()) {
					self?.showError(message)
					self?.modal.loading = false
				}
			}
		}
	}

	@objc private func signUp(sender: AnyObject?) {
//		let requestURL = NSURL(string: "/play?signup=true", relativeToURL: rootURL)
//		let request = NSMutableURLRequest(URL: requestURL!)
//
//		WebManager.sharedInstance.webView!.loadRequest(request)
//		self.performSegueWithIdentifier("successfulLoginSegue", sender:self)
	}

	@objc private func signUpLater(sender: AnyObject?) {
		NSUserDefaults.standardUserDefaults().setBool(true, forKey: "pseudoanonymousUserCreated")
		User.currentUser = User.anonymousUser()
	}


	// MARK: - Private

	@objc private func keyboardWillChangeFrame(notification: NSNotification?) {
		guard let info = notification?.userInfo, value = info[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }

		let frame = value.CGRectValue()
		let visible = max(0, view.bounds.height - frame.origin.y) > 0

		modalTopConstraint.constant = (visible ? -8 : 64)
		modal.layoutIfNeeded()
	}

	private func showError(message: String? = nil) {
		let alert = UIAlertController(title: "Invalid Credentials", message: message, preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
		presentViewController(alert, animated: true, completion: nil)
	}
}


extension SignInViewController: UITextFieldDelegate {
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		if textField == modal.usernameTextField {
			modal.passwordTextField.becomeFirstResponder()
			return false
		}

		signIn(textField)
		return false
	}

	func textFieldDidEndEditing(textField: UITextField) {
		textField.layoutIfNeeded()
	}
}

//  override func viewDidLoad() {
//    super.viewDidLoad()
//    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onWebsiteNotReachable"), name: "websiteNotReachable", object: nil)
//    WebManager.sharedInstance.checkReachibility()
//    //hide button if user created pseudoanonymous user
//    if WebManager.sharedInstance.currentCredentialIsPseudoanonymous() {
//      if WebManager.sharedInstance.getCredentials().first!.user! != UIDevice.currentDevice().identifierForVendor?.UUIDString {
//        WebManager.sharedInstance.clearCredentials()
//        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "pseudoanonymousUserCreated")
//        NSUserDefaults.standardUserDefaults().synchronize()
//      }
//    }
//    if NSUserDefaults.standardUserDefaults().boolForKey("pseudoanonymousUserCreated") || WebManager.sharedInstance.currentCredentialIsPseudoanonymous() {
//      signupLaterButton.enabled = false
//      signupLaterButton.hidden = true
//    }
//  }
//  
//  func onWebsiteNotReachable() {
//    print("onWebsiteNotReachable in login view controller")
//    if memoryAlertController == nil {
//      let titleString = NSLocalizedString("Internet connection problem", comment:"")
//      let messageString = NSLocalizedString("We can't reach the CodeCombat server. Please check your connection and try again.", comment:"")
//      memoryAlertController = UIAlertController(title: titleString, message: messageString, preferredStyle: UIAlertControllerStyle.Alert)
//      memoryAlertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { success in
//        self.memoryAlertController.dismissViewControllerAnimated(true, completion: nil)
//        self.memoryAlertController = nil
//      }))
//      presentViewController(memoryAlertController, animated: true, completion: nil)
//    }
//  }
