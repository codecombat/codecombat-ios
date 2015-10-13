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

	
	// MARK: - Private

	@objc private func update() {
		if let user = User.currentUser {
			// TODO: WebManager.sharedInstance.loginToGetAuthCookie()

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
