//
//  SpellPaletteViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/31/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class SpellPaletteViewController: UIViewController {
  @IBOutlet weak var testDocumentationButton: UIButton!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    WebManager.sharedInstance.scriptMessageNotificationCenter.addObserver(self, selector: Selector("handleTomeUpdateSnippetsNotification:"), name: "tomeUpdateSnippetsHandler", object: nil)
  }
  
  func handleTomeUpdateSnippetsNotification(notification:NSNotification) {
    println(notification.userInfo)
  }
}
