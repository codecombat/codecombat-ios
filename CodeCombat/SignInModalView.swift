//
//  SignInModalView.swift
//  CodeCombat
//
//  Created by Sam Soffes on 10/7/15.
//  Copyright © 2015 CodeCombat. All rights reserved.
//

import UIKit

class SignInModalView: UIImageView {

	// MARK: - Properties

	private let stackView: UIStackView = {
		let view = UIStackView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.axis = .Vertical
		view.distribution = .EqualSpacing
		view.layoutMarginsRelativeArrangement = true
		view.layoutMargins = UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)
		view.spacing = 24
		return view
	}()

	let usernameTextField: UITextField = {
		let field = UITextField()
		field.translatesAutoresizingMaskIntoConstraints = false
		field.placeholder = "Username"
		field.keyboardType = .EmailAddress
		field.autocapitalizationType = .None
		field.autocorrectionType = .No
		field.returnKeyType = .Next
		return field
	}()

	let passwordTextField: UITextField = {
		let field = UITextField()
		field.translatesAutoresizingMaskIntoConstraints = false
		field.placeholder = "Password"
		field.secureTextEntry = true
		field.returnKeyType = .Go
		return field
	}()

	let signInButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.backgroundColor = Color.darkBrown
		button.setTitle("Sign In", forState: .Normal)
		button.layer.cornerRadius = 4
		button.layer.masksToBounds = true
		return button
	}()

	let signUpLaterButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle("Sign Up Later", forState: .Normal)
		button.setTitleColor(Color.darkBrown, forState: .Normal)
		return button
	}()

	let indicator: UIActivityIndicatorView = {
		let view = UIActivityIndicatorView(activityIndicatorStyle: .White)
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	var loading = false {
		didSet {
			usernameTextField.enabled = !loading
			passwordTextField.enabled = !loading
			signInButton.enabled = !loading

			if loading {
				indicator.startAnimating()
			} else {
				indicator.stopAnimating()
			}
		}
	}


	// MARK: - Initializers

	init() {
		super.init(image: UIImage(named: "loginModalBackground"))
		userInteractionEnabled = true

		addSubview(stackView)

		let logo = UIImageView(image: UIImage(named: "Logo"))
		logo.translatesAutoresizingMaskIntoConstraints = false
		logo.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
		logo.contentMode = .ScaleAspectFit
		stackView.addArrangedSubview(logo)

		let fields = UIImageView(image: UIImage(named: "loginInfoBackground"))
		fields.translatesAutoresizingMaskIntoConstraints = false
		fields.userInteractionEnabled = true
		stackView.addArrangedSubview(fields)

		fields.addSubview(usernameTextField)
		fields.addSubview(passwordTextField)

		stackView.addArrangedSubview(signInButton)
		signInButton.addSubview(indicator)

		stackView.addArrangedSubview(signUpLaterButton)

		NSLayoutConstraint.activateConstraints([
			stackView.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
			stackView.trailingAnchor.constraintEqualToAnchor(trailingAnchor),
			stackView.topAnchor.constraintEqualToAnchor(topAnchor),

			NSLayoutConstraint(item: logo, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 144),

			usernameTextField.centerXAnchor.constraintEqualToAnchor(centerXAnchor),
			usernameTextField.topAnchor.constraintEqualToAnchor(fields.topAnchor),
			NSLayoutConstraint(item: usernameTextField, attribute: .Leading, relatedBy: .Equal, toItem: fields, attribute: .Leading, multiplier: 1, constant: 8),
			NSLayoutConstraint(item: usernameTextField, attribute: .Trailing, relatedBy: .Equal, toItem: fields, attribute: .Trailing, multiplier: 1, constant: -8),
			NSLayoutConstraint(item: usernameTextField, attribute: .Height, relatedBy: .Equal, toItem: fields, attribute: .Height, multiplier: 0.5, constant: 0),

			passwordTextField.centerXAnchor.constraintEqualToAnchor(usernameTextField.centerXAnchor),
			passwordTextField.widthAnchor.constraintEqualToAnchor(usernameTextField.widthAnchor),
			passwordTextField.heightAnchor.constraintEqualToAnchor(usernameTextField.heightAnchor),
			NSLayoutConstraint(item: passwordTextField, attribute: .Top, relatedBy: .Equal, toItem: usernameTextField, attribute: .Bottom, multiplier: 1, constant: 0),

			NSLayoutConstraint(item: signInButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 44),

			indicator.centerYAnchor.constraintEqualToAnchor(signInButton.centerYAnchor),
			NSLayoutConstraint(item: indicator, attribute: .Trailing, relatedBy: .Equal, toItem: signInButton, attribute: .Trailing, multiplier: 1, constant: -8)
		])
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
