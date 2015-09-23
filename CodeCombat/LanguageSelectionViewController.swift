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
  let languages = ["English", "русский язык - Russian", "Deutsch (Deutschland) - German (Germany)", "Deutsch (Österreich) - German (Austria)", "Deutsch (Schweiz) - German (Switzerland)", "español (América Latina) - Spanish (Latin America)", "español (ES) - Spanish (Spain)", "简体中文 - Chinese (Simplified)", "繁体中文 - Chinese (Traditional)", "吳語 - Wuu (Traditional)", "français - French", "日本語 - Japanese", "العربية - Arabic", "português do Brasil - Portuguese (Brazil)", "Português (Portugal) - Portuguese (Portugal)", "język polski - Polish", "italiano - Italian", "Türkçe - Turkish", "Nederlands (België) - Dutch (Belgium)", "Nederlands (Nederland) - Dutch (Netherlands)", "فارسی - Persian", "čeština - Czech", "Svenska - Swedish", "ελληνικά - Greek", "limba română - Romanian", "Tiếng Việt - Vietnamese", "magyar - Hungarian", "ไทย - Thai", "dansk - Danish", "한국어 - Korean", "slovenčina - Slovak", "Norsk - Norwegian", "Norsk Bokmål - Norwegian (Bokmål)", "עברית - Hebrew", "српски - Serbian", "українська мова - Ukrainian", "Bahasa Melayu - Bahasa Malaysia", "Català - Catalan"]
  
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
    print("Selected language \(languages[row])")
  }
}
