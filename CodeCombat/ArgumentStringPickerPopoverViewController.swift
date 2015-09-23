//
//  ArgumentStringPickerPopoverView.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 10/28/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

protocol StringPickerPopoverDelegate {
  func stringWasSelectedByStringPickerPopover(selected:String,characterRange:NSRange)
}

class ArgumentStringPickerPopoverViewController: UITableViewController {
  var strings:[String] = []
  var pickerDelegate:StringPickerPopoverDelegate! = nil
  var selectedString:String = ""
  var characterRange:NSRange!
  let rowHeight = 30

  init(stringChoices:[String], characterRange:NSRange) {
    super.init(style: UITableViewStyle.Plain)
    strings = stringChoices
    self.characterRange = characterRange
    clearsSelectionOnViewWillAppear = false
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return strings.count
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return CGFloat(rowHeight)
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cellIdentifier = "Cell"
    var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell!
    if cell == nil {
      cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
    }
    cell.textLabel?.text = strings[indexPath.row]
    return cell
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let selected = strings[indexPath.row]
    
    if pickerDelegate != nil {
      pickerDelegate.stringWasSelectedByStringPickerPopover(selected, characterRange:characterRange)
      dismissViewControllerAnimated(true, completion: nil)
    }
  }
}
