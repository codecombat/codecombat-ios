//
//  CodeCombatIAPHelper.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/30/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class CodeCombatIAPHelper: IAPHelper {
  init() {
    let array = [
      NSString(string:"com.michaelschmatz.CodeCombatiPadTest.amuletOfConditionalAwesomeness"),
      NSString(string:"com.michaelschmatz.CodeCombatiPadTest.gemOfNope"),
      NSString(string:"com.michaelschmatz.CodeCombatiPadTest.wineoutofnowhere")
    ]
    let products = NSMutableArray()
    
    for product in array {
      products.addObject(product)
    }
    let productIdentifiers = NSSet(array: products)
    super.init(productIdentifiers: productIdentifiers)
  }
  class var sharedInstance:CodeCombatIAPHelper {
    return CodeCombatIAPHelperSharedInstance
  }

}
let CodeCombatIAPHelperSharedInstance = CodeCombatIAPHelper()