//
//  LoginViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/26/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import QuartzCore

class LoginViewController: UIViewController {
  @IBOutlet weak var backgroundArtImageView: UIImageView!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var usernameTextField: UITextField!
  @IBOutlet weak var loginActivityIndicatorView: UIActivityIndicatorView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    drawBackgroundGradient()
    WebManager.sharedInstance.createLoginProtectionSpace()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    rememberUser()
  }

  func rememberUser() {
    let credentialsValues = WebManager.sharedInstance.getCredentials()
    if !credentialsValues.isEmpty {
      let credential = credentialsValues.first! as NSURLCredential
      println("User \(credential.user) already connected with saved password; logging in.")
      //User.sharedInstance.name = userJSON["name"] as? String
      User.sharedInstance.email = credential.user!
      User.sharedInstance.password = credential.password!
      segueToMainMenu()
    }
  }
  
  
  @IBAction func login(button:UIButton) {
    loginActivityIndicatorView.startAnimating()
    let username = usernameTextField.text
    let password = passwordTextField.text
    let validationResults = validateLoginCredentials(username: username, password: password)
    if validationResults.isValid {
      performLoginRequest(username: username, password: password)
    } else {
      loginActivityIndicatorView.stopAnimating()
      showInvalidCredentialsAlert(validationResults.errorMessage)
    }
  }
  
  func performLoginRequest(#username:String, password:String) {
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
    var postData = NSJSONSerialization.dataWithJSONObject(LoginCredentials, options: NSJSONWritingOptions(0), error: nil)
    LoginRequest.HTTPBody = postData
    let OperationQueue:NSOperationQueue = NSOperationQueue()
    println("Going to send post data \(postData) for \(LoginCredentials)")
    
    NSURLConnection.sendAsynchronousRequest(LoginRequest, queue: OperationQueue, completionHandler: { [weak self] response, data, requestError -> Void in
      if (requestError != nil) {
        //This will trigger on unauthorized.
        var errorMessage:String
        if data == nil {
          errorMessage = "There was a request error: \(requestError)."
        }
        else {
          var jsonError:NSError?
          var errorObject:AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &jsonError)!
          if jsonError != nil {
            errorMessage = "There was an unknown error logging in."
          } else {
            let ErrorDictionaries = errorObject as? [[String:String]]
            if ErrorDictionaries![0]["property"] == "password" {
              errorMessage = "The password for your account is incorrect."
            } else if ErrorDictionaries![0]["property"] == "email" {
              errorMessage = "We couldn't find an account for that email."
            } else {
              errorMessage = "Your credentials are incorrect."
            }
          }
        }
        dispatch_async(dispatch_get_main_queue(), {
          self!.handleLoginFailure(errorMessage)
        })
      } else {
        var jsonError:NSError?
        var userJSON = NSJSONSerialization.JSONObjectWithData(data,
          options: NSJSONReadingOptions.MutableContainers,
          error: &jsonError) as NSDictionary
        
        if jsonError != nil {
          println("JSON serialization error: \(jsonError!)")
          let ErrorString = NSString(data: data, encoding: NSUTF8StringEncoding)
          println("Got data:\(ErrorString)")
        } else {
          User.sharedInstance.name = userJSON["name"] as? String
          User.sharedInstance.email = userJSON["email"] as? String
          User.sharedInstance.password = password
          dispatch_async(dispatch_get_main_queue(), {
            WebManager.sharedInstance.saveUser()
            self!.segueToMainMenu()
          })
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
      title: "Login failure",
      message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
    message.show()
  }
  
  private func showInvalidCredentialsAlert(errorMessage:String) {
    let message:UIAlertView = UIAlertView(
      title: "Invalid credentials",
      message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
    message.show()
  }
  private func validateLoginCredentials(#username:String,
    password:String) -> (isValid:Bool, errorMessage:String) {
    if username.isEmpty && password.isEmpty {
      return (false, "Please input a username and password.")
    }
    else if username.isEmpty {
      return (false,"Please input a username.")
    } else if password.isEmpty {
      return (false, "Please input a password.")
    }
    return (true, "Credentials are valid.")
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
