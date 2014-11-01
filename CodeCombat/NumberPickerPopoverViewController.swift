//
//  NumberPickerPopoverViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 11/1/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

protocol NumberPickerPopoverDelegate {
  func didSelectNumber(number:Int, characterRange:NSRange)
}

class NumberPickerPopoverViewController: UIViewController {
  
  @IBOutlet weak var entryNumberLabel: UILabel!
  var pickerDelegate:NumberPickerPopoverDelegate? = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
    println("VIEW LOADED")
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBOutlet weak var oneButton: UIButton!
  
  
  @IBAction func numberButtonWasTapped(sender:UIButton) {
    entryNumberLabel.text = "1"
  }
  
  /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  // Get the new view controller using segue.destinationViewController.
  // Pass the selected object to the new view controller.
  }
  */
  
}