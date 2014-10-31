//
//  ArgumentOverlayView.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 10/28/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

class ArgumentOverlayView: UIButton, StringPickerPopoverDelegate {
  var characterRange:NSRange! //represents the character range this view is over
  var editorTextViewController:EditorTextViewController!
  var currentLevelName = ""
  var currentFunctionName = ""
  var defaultContentsToInsertOnRun = ""
  func setupView(levelName:String, functionName:String) {
    currentLevelName = levelName
    currentFunctionName = functionName
    backgroundColor = UIColor.redColor()
    //round the corners
    layer.cornerRadius = 10
    layer.masksToBounds = true
    println("Setting up view for level \(levelName)")
    if levelName == "true-names" {
      setupTrueNames()
    } else if levelName == "the-raised-sword" {
      setupTheRaisedSword()
    } else if levelName == "new-sight" {
      setupNewSight()
    }
    addTarget(self, action: Selector("onTapped"), forControlEvents: .TouchUpInside)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onCodeRun"), name: "codeRun", object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func setupNewSight() {
    let defaultLabel = makeDefaultLabelWithText("\"Door\"")
    addSubview(defaultLabel)
  }
  func setupTheRaisedSword() {
    let defaultLabel = makeDefaultLabelWithText("\"Gurt\"")
    addSubview(defaultLabel)
  }
  
  func setupTrueNames() {
    //only function is attack
    let defaultLabel = makeDefaultLabelWithText("\"Brak\"")
    addSubview(defaultLabel)
  }
  
  func makeDefaultLabelWithText(text:String) -> UILabel {
    let defaultLabel = UILabel(frame: CGRect(x: 0, y: editorTextViewController.textView.lineSpacing, width: 0, height: 0))
    defaultLabel.text = text
    defaultLabel.font = editorTextViewController.currentFont!
    defaultLabel.sizeToFit()
    defaultContentsToInsertOnRun = text
    return defaultLabel
  }
  
  func resetLocationToCurrentCharacterRange() {
    let glyphRange = editorTextViewController.layoutManager.glyphRangeForCharacterRange(characterRange, actualCharacterRange: nil)
    var boundingRect = editorTextViewController.layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: editorTextViewController.textContainer)
    boundingRect.origin.y += editorTextViewController.textView.lineSpacing
    frame = boundingRect
    setNeedsDisplay()
  }
  
  func onCodeRun() {
    //Insert the default choice
    stringWasSelectedByStringPickerPopover(defaultContentsToInsertOnRun)
  }
  
  func onTapped() {
    //create the view here
    if currentLevelName == "true-names" {
      let choices = ["\"Brak\"","\"Treg\""]
      makeStringChoicePopoverWithChoices(choices)
    } else if currentLevelName == "the-raised-sword" {
      let choices = ["\"Gurt\"","\"Rig\"","\"Ack\""]
      makeStringChoicePopoverWithChoices(choices)
    } else if currentLevelName == "new-sight" {
      makeStringChoicePopoverWithChoices(["\"Door\""])
    }
  }
  
  func makeStringChoicePopoverWithChoices(choices:[String]) {
    let stringPickerViewController = ArgumentStringPickerPopoverViewController(stringChoices: choices)
    stringPickerViewController.pickerDelegate = self
    let popover = UIPopoverController(contentViewController: stringPickerViewController)
    popover.setPopoverContentSize(CGSize(width: 100, height: stringPickerViewController.rowHeight*choices.count), animated: true)
    popover.presentPopoverFromRect(frame, inView: superview!, permittedArrowDirections: .Down | .Up, animated: true)
  }
  
  func stringWasSelectedByStringPickerPopover(selected:String) {
    editorTextViewController.textStorage.replaceCharactersInRange(characterRange, withString: selected)
    self.hidden = true
  }
  
}
