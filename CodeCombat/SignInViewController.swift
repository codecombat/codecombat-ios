//
//  SignInViewController.swift
//  iPadClient
//
//  Created by Sam Soffes on 10/7/15.
//  Copyright (c) 2015 CodeCombat. All rights reserved.
//

import UIKit

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
		view.addSubview(modal)

		modalTopConstraint = NSLayoutConstraint(item: modal, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 32)

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

		modal.usernameTextField.enabled = false
		modal.passwordTextField.enabled = false
		modal.signInButton.enabled = false
		modal.indicator.startAnimating()

//		loginActivityIndicatorView.startAnimating()
//		performLoginRequest(username: username, password: password)
	}

	@objc private func signUp(sender: AnyObject?) {
//		let requestURL = NSURL(string: "/play?signup=true", relativeToURL: rootURL)
//		let request = NSMutableURLRequest(URL: requestURL!)
//
//		WebManager.sharedInstance.webView!.loadRequest(request)
//		self.performSegueWithIdentifier("successfulLoginSegue", sender:self)
	}

	@objc private func signUpLater(sender: AnyObject?) {
		User.sharedInstance.email = UIDevice.currentDevice().identifierForVendor?.UUIDString
		User.sharedInstance.password = User.randomPassword()
		WebManager.sharedInstance.saveUser()
		WebManager.sharedInstance.createAnonymousUser()

		NSUserDefaults.standardUserDefaults().setBool(true, forKey: "pseudoanonymousUserCreated")

		// TODO: Show game
//		self.performSegueWithIdentifier("successfulLoginSegue", sender:self)
	}


	// MARK: - Private

	@objc private func keyboardWillChangeFrame(notification: NSNotification?) {
		guard let info = notification?.userInfo,
			value = info[UIKeyboardFrameEndUserInfoKey] as? NSValue,
			duration = info[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval,
			rawCurve = info[UIKeyboardAnimationCurveUserInfoKey] as? Int,
			curve = UIViewAnimationCurve(rawValue: rawCurve)
		else { return }

		let frame = value.CGRectValue()
		let visible = max(0, view.bounds.height - frame.origin.y) > 0

		UIView.beginAnimations("keyboard", context: nil)
		UIView.setAnimationDuration(duration)
		UIView.setAnimationCurve(curve)
		modalTopConstraint.constant = 32 - (visible ? 16 : 0)
		modal.layoutIfNeeded()
		UIView.commitAnimations()
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
}
//  @IBOutlet weak var loginActivityIndicatorView: UIActivityIndicatorView!
//
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
//  
//  func performLoginRequest(username username:String, password:String) {
//    let RootURL = WebManager.sharedInstance.rootURL
//    let LoginURL:NSURL = NSURL(string: "/auth/login", relativeToURL: RootURL)!
//    let LoginRequest:NSMutableURLRequest = NSMutableURLRequest(
//      URL: LoginURL,
//      cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
//      timeoutInterval: 5.0)
//    
//    LoginRequest.HTTPMethod = "POST"
//    LoginRequest.setValue("application/json",
//      forHTTPHeaderField: "Content-Type")
//    let LoginCredentials: [String:String] = [
//      "username": username,
//      "password": password
//    ]
//    let postData = try? NSJSONSerialization.dataWithJSONObject(LoginCredentials, options: NSJSONWritingOptions(rawValue: 0))
//    LoginRequest.HTTPBody = postData
//    let OperationQueue:NSOperationQueue = NSOperationQueue()
//    //print("Going to send post data \(postData) for \(LoginCredentials)")
//    
//    NSURLConnection.sendAsynchronousRequest(LoginRequest, queue: OperationQueue, completionHandler: { [weak self] response, data, requestError -> Void in
//      if (requestError != nil) {
//        //This will trigger on unauthorized.
//        var errorMessage:String
//        if data == nil {
//          errorMessage = NSLocalizedString("There was a request error: \(requestError).", comment:"")
//        }
//        else {
//          let errorObject:AnyObject = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
//          let ErrorDictionaries = errorObject as? [[String:String]]
//          if ErrorDictionaries![0]["property"] == "password" {
//            errorMessage = NSLocalizedString("The password for your account is incorrect.", comment:"")
//          } else if ErrorDictionaries![0]["property"] == "email" {
//            errorMessage = NSLocalizedString("We couldn't find an account for that email.", comment:"")
//          } else {
//            errorMessage = NSLocalizedString("Your credentials are incorrect.", comment:"")
//          }
//        }
//        dispatch_async(dispatch_get_main_queue(), {
//          self!.handleLoginFailure(errorMessage)
//        })
//      } else {
//        do {
//          let userJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
//          guard (userJSON as? NSDictionary != nil) else {
//            print("Error: userJSON isn't a Dictionary")
//            return
//          }
//          print("JSON is: \(userJSON)")
//          User.sharedInstance.name = (userJSON as! NSDictionary).objectForKey("name") as? String
//          User.sharedInstance.email = (userJSON as! NSDictionary).objectForKey("email") as? String
//          User.sharedInstance.password = password
//          WebManager.sharedInstance.authCookieIsFresh = true
//          dispatch_async(dispatch_get_main_queue(), {
//            self!.loginActivityIndicatorView.stopAnimating()
//            WebManager.sharedInstance.saveUser()
//            self!.segueToMainMenu()
//          })
//        }
//        catch let JSONError as NSError {
//          print("There was an error serializing the user JSON")
//          print("\(JSONError)")
//        }
//      }
//      })
//  }
