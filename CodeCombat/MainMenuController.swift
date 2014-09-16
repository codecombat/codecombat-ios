//
//  MainMenuController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/27/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class MainMenuController: UIViewController {

  @IBOutlet weak var playerNameLabel: UILabel!
  @IBOutlet weak var testPlayButton: UIButton!
    
  override func viewDidLoad() {
    
    playerNameLabel.text = User.sharedInstance.name
    if playerNameLabel.text == nil {
      playerNameLabel.text = "New Player"
    }
  }
    
  @IBAction func testPlayLevel() {
    self.performSegueWithIdentifier("playLevel", sender: self)
  }
  
  @IBAction func loginScreenSegue() {
    self.performSegueWithIdentifier("loginScreenSegue", sender: self)
  }

}
