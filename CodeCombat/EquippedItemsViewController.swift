//
//  EquippedItemsViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/30/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class EquippedItemsViewController: PlayViewChildViewController {
  
  @IBOutlet weak var currentlyEquippedItemButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  @IBAction func useCurrentlyEquippedItem(sender:AnyObject) {
    let ConditionalTemplate =
      "if ({{condition}}) {\n" +
      "\t //Your content here\n" +
      "} else {\n" +
      "\t //Some other conditional\n" +
      "}"
    
    let UserInfo = NSDictionary(dictionary:["textToInsert":ConditionalTemplate])
  NSNotificationCenter.defaultCenter().postNotificationName("interfaceTextInsertion",
      object: self,
      userInfo:UserInfo)
  }

}
