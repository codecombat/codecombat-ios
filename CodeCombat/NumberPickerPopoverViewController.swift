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
  var characterRange:NSRange!
  override func viewDidLoad() {
    super.viewDidLoad()
    entryNumberLabel.text! = "0"
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBOutlet weak var oneButton: UIButton!
  
  
  @IBAction func numberButtonWasTapped(sender:UIButton) {
    if entryNumberLabel.text! == "0" {
      entryNumberLabel.text = sender.titleLabel!.text!
    } else {
      entryNumberLabel.text = entryNumberLabel.text!.stringByAppendingString(sender.titleLabel!.text!)
    }
    
  }
  
  @IBAction func okayWasTapped(sender:UIButton) {
    pickerDelegate?.didSelectNumber(Int(entryNumberLabel.text!)!, characterRange: characterRange)
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func deleteWasTapped(sender:UIButton) {
    if (entryNumberLabel.text!).characters.count == 1{
      entryNumberLabel.text! = "0"
    } else {
      entryNumberLabel.text!.removeAtIndex(entryNumberLabel.text!.endIndex.predecessor())
    }
    
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