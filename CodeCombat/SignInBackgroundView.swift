//
//  SignInBackgroundView.swift
//  CodeCombat
//
//  Created by Sam Soffes on 10/7/15.
//  Copyright © 2015 CodeCombat. All rights reserved.
//

import UIKit

class SignInBackgroundView: UIView {

	// MARK: - Initializers

	convenience init() {
		self.init(frame: .zero)
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		let art = UIImageView(image: UIImage(named: "loginArtBackground"))
		art.translatesAutoresizingMaskIntoConstraints = false
		addSubview(art)

		NSLayoutConstraint.activateConstraints([
			art.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
			art.trailingAnchor.constraintEqualToAnchor(trailingAnchor),
			art.topAnchor.constraintEqualToAnchor(topAnchor)
		])
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}


	// MARK: - UIView

	override func drawRect(rect: CGRect) {
		guard let context = UIGraphicsGetCurrentContext(),
			gradient = CGGradientCreateWithColors(nil, [Color.grassGreen.CGColor, Color.darkBrown.CGColor], [0.57, 0.95])
		else { return }

		CGContextDrawLinearGradient(context, gradient, .zero, CGPoint(x: 0, y: bounds.maxY), [])
	}
}
