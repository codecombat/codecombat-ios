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


	// MARK: - Initializers

	init() {
		super.init(image: UIImage(named: "loginModalBackground"))
		userInteractionEnabled = true

		let logo = UIImageView(image: UIImage(named: "Logo"))
		logo.translatesAutoresizingMaskIntoConstraints = false
		logo.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
		logo.contentMode = .ScaleAspectFit
		addSubview(logo)

		let fields = UIImageView(image: UIImage(named: "loginInfoBackground"))
		fields.translatesAutoresizingMaskIntoConstraints = false
		fields.userInteractionEnabled = true
		addSubview(fields)

		fields.addSubview(usernameTextField)
		fields.addSubview(passwordTextField)

		addSubview(signInButton)

		NSLayoutConstraint.activateConstraints([
			logo.centerXAnchor.constraintEqualToAnchor(centerXAnchor),
			NSLayoutConstraint(item: logo, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: -8),
			NSLayoutConstraint(item: logo, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 0.8, constant: 0),

			fields.centerXAnchor.constraintEqualToAnchor(centerXAnchor),
			NSLayoutConstraint(item: fields, attribute: .Top, relatedBy: .Equal, toItem: logo, attribute: .Bottom, multiplier: 1, constant: -8),

			usernameTextField.centerXAnchor.constraintEqualToAnchor(centerXAnchor),
			usernameTextField.topAnchor.constraintEqualToAnchor(fields.topAnchor),
			NSLayoutConstraint(item: usernameTextField, attribute: .Leading, relatedBy: .Equal, toItem: fields, attribute: .Leading, multiplier: 1, constant: 8),
			NSLayoutConstraint(item: usernameTextField, attribute: .Trailing, relatedBy: .Equal, toItem: fields, attribute: .Trailing, multiplier: 1, constant: -8),
			NSLayoutConstraint(item: usernameTextField, attribute: .Height, relatedBy: .Equal, toItem: fields, attribute: .Height, multiplier: 0.5, constant: 0),

			passwordTextField.centerXAnchor.constraintEqualToAnchor(usernameTextField.centerXAnchor),
			passwordTextField.widthAnchor.constraintEqualToAnchor(usernameTextField.widthAnchor),
			passwordTextField.heightAnchor.constraintEqualToAnchor(usernameTextField.heightAnchor),
			NSLayoutConstraint(item: passwordTextField, attribute: .Top, relatedBy: .Equal, toItem: usernameTextField, attribute: .Bottom, multiplier: 1, constant: 0),

			signInButton.widthAnchor.constraintEqualToAnchor(fields.widthAnchor),
			signInButton.centerXAnchor.constraintEqualToAnchor(centerXAnchor),
			NSLayoutConstraint(item: signInButton, attribute: .Top, relatedBy: .Equal, toItem: fields, attribute: .Bottom, multiplier: 1, constant: 16),
			NSLayoutConstraint(item: signInButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 44)

		])
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
