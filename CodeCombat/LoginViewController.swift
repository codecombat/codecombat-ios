//
//  LoginViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/26/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import QuartzCore

class LoginViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet weak var backgroundArtImageView: UIImageView!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var signupLaterButton: UIButton!
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var loginActivityIndicatorView: UIActivityIndicatorView!
  var memoryAlertController:UIAlertController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    drawBackgroundGradient()
    WebManager.sharedInstance.createLoginProtectionSpace()
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onWebsiteNotReachable"), name: "websiteNotReachable", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onWebsiteReachable"), name: "websiteReachable", object: nil)
    WebManager.sharedInstance.checkReachibility()
    usernameTextField.delegate = self
    passwordTextField.delegate = self
    //hide button if user created pseudoanonymous user
    if WebManager.sharedInstance.currentCredentialIsPseudoanonymous() {
      if WebManager.sharedInstance.getCredentials().first!.user! != UIDevice.currentDevice().identifierForVendor?.UUIDString {
        WebManager.sharedInstance.clearCredentials()
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "pseudoanonymousUserCreated")
        NSUserDefaults.standardUserDefaults().synchronize()
      }
    }
    if NSUserDefaults.standardUserDefaults().boolForKey("pseudoanonymousUserCreated") || WebManager.sharedInstance.currentCredentialIsPseudoanonymous() {
      signupLaterButton.enabled = false
      signupLaterButton.hidden = true
    }
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    if textField == usernameTextField {
      if passwordTextField.text != nil && passwordTextField.text!.characters.count > 0 {
        login(loginButton)
      } else {
        usernameTextField.resignFirstResponder()
        passwordTextField.becomeFirstResponder()
      }
      return false
    } else if textField == passwordTextField {
      login(loginButton)
      return false
    }
    return true
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    rememberUser()
  }
  
  func onWebsiteNotReachable() {
    print("onWebsiteNotReachable in login view controller")
    if memoryAlertController == nil {
      let titleString = NSLocalizedString("Internet connection problem", comment:"")
      let messageString = NSLocalizedString("We can't reach the CodeCombat server. Please check your connection and try again.", comment:"")
      memoryAlertController = UIAlertController(title: titleString, message: messageString, preferredStyle: UIAlertControllerStyle.Alert)
      memoryAlertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { success in
        self.memoryAlertController.dismissViewControllerAnimated(true, completion: nil)
        self.memoryAlertController = nil
      }))
      presentViewController(memoryAlertController, animated: true, completion: nil)
    }
  }
  
  func onWebsiteReachable() {
    if memoryAlertController != nil {
      memoryAlertController.dismissViewControllerAnimated(true, completion: {
        self.memoryAlertController = nil
      })
    }
  }
  
  func rememberUser() {
    let credentialsValues = WebManager.sharedInstance.getCredentials()
    if !credentialsValues.isEmpty {
      let credential = credentialsValues.first! as NSURLCredential
      if WebManager.sharedInstance.currentCredentialIsPseudoanonymous() {
        if credential.user! != UIDevice.currentDevice().identifierForVendor?.UUIDString {
          WebManager.sharedInstance.clearCredentials()
          let defaults = NSUserDefaults.standardUserDefaults()
          defaults.setBool(false, forKey: "pseudoanonymousUserCreated")
          defaults.synchronize()
          return
        }
      }
      print("User \(credential.user) already connected with saved password; logging in.")
      //User.sharedInstance.name = userJSON["name"] as? String
      User.sharedInstance.email = credential.user!
      User.sharedInstance.password = credential.password!
      segueToMainMenu()
      WebManager.sharedInstance.loginToGetAuthCookie()
    }
  }
  
  
  @IBAction func login(button:UIButton) {
    loginActivityIndicatorView.startAnimating()
    let username = usernameTextField.text!
    let password = passwordTextField.text!
    let validationResults = validateLoginCredentials(username: username, password: password)
    if validationResults.isValid {
      performLoginRequest(username: username, password: password)
    } else {
      loginActivityIndicatorView.stopAnimating()
      showInvalidCredentialsAlert(validationResults.errorMessage)
    }
  }
  
  @IBAction func signup(button: UIButton) {
    let requestURL = NSURL(string: "/play?signup=true", relativeToURL: WebManager.sharedInstance.rootURL)
    let request = NSMutableURLRequest(URL: requestURL!)
    
    WebManager.sharedInstance.webView!.loadRequest(request)
    self.performSegueWithIdentifier("successfulLoginSegue", sender:self)
  }
  
  @IBAction func signupLater(button:UIButton) {
    let deviceIdentifier = UIDevice.currentDevice().identifierForVendor?.UUIDString
    let randomPassword = generateRandomPassword()
    User.sharedInstance.email = deviceIdentifier
    User.sharedInstance.password = randomPassword
    WebManager.sharedInstance.saveUser()
    WebManager.sharedInstance.createAnonymousUser()
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setBool(true, forKey: "pseudoanonymousUserCreated")
    defaults.synchronize()
    self.performSegueWithIdentifier("successfulLoginSegue", sender:self)
  
  }
  
  private func generateRandomPassword() -> String {
    let passChars:NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789!@#$%^&*()90"
    let pass = NSMutableString(capacity: 30)
    for (var i = 0; i < 25; i++) {
      let random = Int(arc4random_uniform(UInt32(passChars.length)))
      let char = passChars.characterAtIndex(random)
      pass.appendFormat("%C", char)
    }
    return pass as String
  }
  
  func performLoginRequest(username username:String, password:String) {
    let RootURL = WebManager.sharedInstance.rootURL
    let LoginURL:NSURL = NSURL(string: "/auth/login", relativeToURL: RootURL)!
    let LoginRequest:NSMutableURLRequest = NSMutableURLRequest(
      URL: LoginURL,
      cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
      timeoutInterval: 5.0)
    
    LoginRequest.HTTPMethod = "POST"
    LoginRequest.setValue("application/json",
      forHTTPHeaderField: "Content-Type")
    let LoginCredentials: [String:String] = [
      "username": username,
      "password": password
    ]
    let postData = try? NSJSONSerialization.dataWithJSONObject(LoginCredentials, options: NSJSONWritingOptions(rawValue: 0))
    LoginRequest.HTTPBody = postData
    let OperationQueue:NSOperationQueue = NSOperationQueue()
    //print("Going to send post data \(postData) for \(LoginCredentials)")
    
    NSURLConnection.sendAsynchronousRequest(LoginRequest, queue: OperationQueue, completionHandler: { [weak self] response, data, requestError -> Void in
      if (requestError != nil) {
        //This will trigger on unauthorized.
        var errorMessage:String
        if data == nil {
          errorMessage = NSLocalizedString("There was a request error: \(requestError).", comment:"")
        }
        else {
          let errorObject:AnyObject = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
          let ErrorDictionaries = errorObject as? [[String:String]]
          if ErrorDictionaries![0]["property"] == "password" {
            errorMessage = NSLocalizedString("The password for your account is incorrect.", comment:"")
          } else if ErrorDictionaries![0]["property"] == "email" {
            errorMessage = NSLocalizedString("We couldn't find an account for that email.", comment:"")
          } else {
            errorMessage = NSLocalizedString("Your credentials are incorrect.", comment:"")
          }
        }
        dispatch_async(dispatch_get_main_queue(), {
          self!.handleLoginFailure(errorMessage)
        })
      } else {
        do {
          let userJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
          guard (userJSON as? NSDictionary != nil) else {
            print("Error: userJSON isn't a Dictionary")
            return
          }
          print("JSON is: \(userJSON)")
          User.sharedInstance.name = (userJSON as! NSDictionary).objectForKey("name") as? String
          User.sharedInstance.email = (userJSON as! NSDictionary).objectForKey("email") as? String
          User.sharedInstance.password = password
          WebManager.sharedInstance.authCookieIsFresh = true
          dispatch_async(dispatch_get_main_queue(), {
            self!.loginActivityIndicatorView.stopAnimating()
            WebManager.sharedInstance.saveUser()
            self!.segueToMainMenu()
          })
        }
        catch let JSONError as NSError {
          print("There was an error serializing the user JSON")
          print("\(JSONError)")
        }
      }
      })
  }
  
  func segueToMainMenu() {
    WebManager.sharedInstance.logIn(email: User.sharedInstance.email!, password: User.sharedInstance.password!)
    self.performSegueWithIdentifier("successfulLoginSegue", sender:self)
  }
  
  func handleLoginFailure(errorMessage:String) {
    self.loginActivityIndicatorView.stopAnimating()
    let message:UIAlertView = UIAlertView(
      title: NSLocalizedString("Login failure", comment:""),
      message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
    message.show()
  }
  
  private func showInvalidCredentialsAlert(errorMessage:String) {
    let message:UIAlertView = UIAlertView(
      title: NSLocalizedString("Invalid credentials", comment:""),
      message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
    message.show()
  }
  
  private func validateLoginCredentials(username username:String = "", password:String = "") -> (isValid:Bool, errorMessage:String) {
    if username.isEmpty && password.isEmpty {
      return (false, NSLocalizedString("Please input a username and password.", comment:""))
    }
    else if username.isEmpty {
      return (false,NSLocalizedString("Please input a username.", comment:""))
    } else if password.isEmpty {
      return (false, NSLocalizedString("Please input a password.", comment:""))
    }
    return (true, NSLocalizedString("Credentials are valid.", comment:""))
  }
  
  func drawBackgroundGradient() {
    let colorManager:ColorManager = ColorManager.sharedInstance
    let gradientColors: Array <AnyObject> = [colorManager.grassGreen.CGColor, colorManager.darkBrown.CGColor] //should auto-bridge
    //conver this to a more sustainable solution
    let gradientStops: [Float] = [0.5703125,0.95]
    let gradientLayer:CAGradientLayer = CAGradientLayer()
    gradientLayer.colors = gradientColors
    gradientLayer.locations = gradientStops
    gradientLayer.frame = self.view.bounds
    self.view.layer.insertSublayer(gradientLayer, atIndex: 0)
    
  }
  
}
