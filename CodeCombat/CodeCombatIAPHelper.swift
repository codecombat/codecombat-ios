//
//  CodeCombatIAPHelper.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/30/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

enum IAP:String {
  case Gems5 = "gems_5"
  case Gems10 = "gems_10"
  case Gems20 = "gems_20"
}

class CodeCombatIAPHelper: IAPHelper {
  init() {
    let products:[String] = [
      IAP.Gems5.rawValue,
      IAP.Gems10.rawValue,
      IAP.Gems20.rawValue
    ]
    let productIdentifiers = NSSet(array: products)
    super.init(productIdentifiers: productIdentifiers)
  }
  class var sharedInstance:CodeCombatIAPHelper {
    return CodeCombatIAPHelperSharedInstance
  }

}
let CodeCombatIAPHelperSharedInstance = CodeCombatIAPHelper()