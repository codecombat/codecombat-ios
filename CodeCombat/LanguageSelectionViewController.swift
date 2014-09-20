//
//  LanguageSelectionViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 9/20/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class LanguageSelectionViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
  
  @IBOutlet weak var doneButton: UIButton!
  @IBOutlet weak var languagePickerView: UIPickerView!
  let languages = ["English","Deutsch","中文(简体字)","日本語","한국어"]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    languagePickerView.dataSource = self
    languagePickerView.delegate = self
    // Do any additional setup after loading the view.
  }

  @IBAction func clickDone() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return languages.count
  }
  
  func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
    return languages[row]
  }
  
  func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    println("Selected language \(languages[row])")
  }
}
