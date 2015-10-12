//
//  RootViewController.swift
//  CodeCombat
//
//  Created by Sam Soffes on 10/7/15.
//  Copyright © 2015 CodeCombat. All rights reserved.
//

import UIKit

/// Root view controller of the window that manages transitioning between sign in and the game
class RootViewController: UIViewController {

	// MARK: - Properties

	private var viewController: UIViewController? {
		willSet {
			guard let viewController = viewController else { return }
			viewController.willMoveToParentViewController(nil)
			viewController.view.removeFromSuperview()
			viewController.removeFromParentViewController()
		}

		didSet {
			guard let viewController = viewController else { return }

			viewController.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

			addChildViewController(viewController)
			view.addSubview(viewController.view)
			viewController.didMoveToParentViewController(self)

			setNeedsStatusBarAppearanceUpdate()
		}
	}


	// MARK: - Initializers

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}


	// MARK: - UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()
		update()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "update", name: User.currentUserDidChangeNotificationName, object: nil)
	}

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

	
	// MARK: - Private

	@objc private func update() {
		if let user = User.currentUser {
			if let viewController = viewController as? GameViewController {
				viewController.user = user
			} else {
				viewController = GameViewController(user: user)
			}
		} else {
			viewController = SignInViewController()
		}
	}
}
