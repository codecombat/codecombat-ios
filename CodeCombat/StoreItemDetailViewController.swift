//
//  StoreItemDetailView.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/31/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import StoreKit

class StoreItemDetailViewController: UIViewController {
  
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var buyButton: UIButton!
  @IBOutlet weak var itemImageView: UIImageView!
  @IBOutlet weak var itemDescriptionLabel: UILabel!
  @IBOutlet weak var itemTitleLabel: UILabel!
  
  var priceFormatter:NSNumberFormatter?
  
  var product:SKProduct!
  @IBAction func done(sender:AnyObject?) {
    dismissViewControllerAnimated(true, completion: nil)
    
  }
  
  
  override func viewDidLoad() {
    itemDescriptionLabel.text = product.localizedDescription
    itemTitleLabel.text = product.localizedTitle
    if product.productIdentifier == "com.michaelschmatz.CodeCombatiPadTest.amuletOfConditionalAwesomeness" {
      itemImageView.image = UIImage(named: "amuletOfConditional")
    } else if product.productIdentifier == "com.michaelschmatz.CodeCombatiPadTest.gemOfNope"{
      itemImageView.image = UIImage(named: "gemOfNope")
    } else if product.productIdentifier == "com.michaelschmatz.CodeCombatiPadTest.wineoutofnowhere" {
      itemImageView.image = UIImage(named:"wine")
    }
    priceFormatter = NSNumberFormatter()
    priceFormatter!.formatterBehavior = NSNumberFormatterBehavior.Behavior10_4
    priceFormatter!.numberStyle = NSNumberFormatterStyle.CurrencyStyle
    
    priceFormatter!.locale = product.priceLocale
    priceLabel.text = priceFormatter?.stringFromNumber(product.price)
    if CodeCombatIAPHelper.sharedInstance.productPurchased(product.productIdentifier) {
      buyButton.enabled = false
      buyButton.setTitle("Purchased", forState: UIControlState.Normal)
    } else {
      buyButton.addTarget(self, action: Selector("buy:"), forControlEvents: UIControlEvents.TouchUpInside)
    }
  }
  @IBAction func buy(sender:AnyObject?) {
    let buyButton = sender as UIButton
    println("Buying product \(product.localizedTitle)")
    CodeCombatIAPHelper.sharedInstance.buyProduct(product)
  }
}
