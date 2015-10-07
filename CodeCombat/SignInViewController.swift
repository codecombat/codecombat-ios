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
//		loginActivityIndicatorView.startAnimating()
//		let username = usernameTextField.text!
//		let password = passwordTextField.text!
//		let validationResults = validateLoginCredentials(username: username, password: password)
//
//		if validationResults.isValid {
//			performLoginRequest(username: username, password: password)
//		} else {
//			loginActivityIndicatorView.stopAnimating()
//			showInvalidCredentialsAlert(validationResults.errorMessage)
//		}
	}

	@objc private func signUp(sender: AnyObject?) {
//		let requestURL = NSURL(string: "/play?signup=true", relativeToURL: WebManager.sharedInstance.rootURL)
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

//  @IBOutlet weak var backgroundArtImageView: UIImageView!
//  @IBOutlet weak var loginButton: UIButton!
//  @IBOutlet weak var passwordTextField: UITextField!
//  @IBOutlet weak var signupLaterButton: UIButton!
//  @IBOutlet weak var usernameTextField: UITextField!
//  @IBOutlet weak var loginActivityIndicatorView: UIActivityIndicatorView!
//  var memoryAlertController:UIAlertController!
//  
//  override func viewDidLoad() {
//    super.viewDidLoad()
//    drawBackgroundGradient()
//    WebManager.sharedInstance.createLoginProtectionSpace()
//    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onWebsiteNotReachable"), name: "websiteNotReachable", object: nil)
//    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onWebsiteReachable"), name: "websiteReachable", object: nil)
//    WebManager.sharedInstance.checkReachibility()
//    usernameTextField.delegate = self
//    passwordTextField.delegate = self
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
//  override func viewDidAppear(animated: Bool) {
//    super.viewDidAppear(animated)
//    rememberUser()
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
//  func onWebsiteReachable() {
//    if memoryAlertController != nil {
//      memoryAlertController.dismissViewControllerAnimated(true, completion: {
//        self.memoryAlertController = nil
//      })
//    }
//  }
//  
//  func rememberUser() {
//    let credentialsValues = WebManager.sharedInstance.getCredentials()
//    if !credentialsValues.isEmpty {
//      let credential = credentialsValues.first! as NSURLCredential
//      if WebManager.sharedInstance.currentCredentialIsPseudoanonymous() {
//        if credential.user! != UIDevice.currentDevice().identifierForVendor?.UUIDString {
//          WebManager.sharedInstance.clearCredentials()
//          let defaults = NSUserDefaults.standardUserDefaults()
//          defaults.setBool(false, forKey: "pseudoanonymousUserCreated")
//          defaults.synchronize()
//          return
//        }
//      }
//      print("User \(credential.user) already connected with saved password; logging in.")
//      //User.sharedInstance.name = userJSON["name"] as? String
//      User.sharedInstance.email = credential.user!
//      User.sharedInstance.password = credential.password!
//      segueToMainMenu()
//      WebManager.sharedInstance.loginToGetAuthCookie()
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
//  
//  func segueToMainMenu() {
//    WebManager.sharedInstance.logIn(email: User.sharedInstance.email!, password: User.sharedInstance.password!)
//    self.performSegueWithIdentifier("successfulLoginSegue", sender:self)
//  }
//  
//  func handleLoginFailure(errorMessage:String) {
//    self.loginActivityIndicatorView.stopAnimating()
//    let message:UIAlertView = UIAlertView(
//      title: NSLocalizedString("Login failure", comment:""),
//      message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
//    message.show()
//  }
//  
//  private func showInvalidCredentialsAlert(errorMessage:String) {
//    let message:UIAlertView = UIAlertView(
//      title: NSLocalizedString("Invalid credentials", comment:""),
//      message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
//    message.show()
//  }
//  
//  private func validateLoginCredentials(username username:String = "", password:String = "") -> (isValid:Bool, errorMessage:String) {
//    if username.isEmpty && password.isEmpty {
//      return (false, NSLocalizedString("Please input a username and password.", comment:""))
//    }
//    else if username.isEmpty {
//      return (false,NSLocalizedString("Please input a username.", comment:""))
//    } else if password.isEmpty {
//      return (false, NSLocalizedString("Please input a password.", comment:""))
//    }
//    return (true, NSLocalizedString("Credentials are valid.", comment:""))
//  }
