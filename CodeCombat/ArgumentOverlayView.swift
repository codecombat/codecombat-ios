//
//  ArgumentOverlayView.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 10/28/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

class ArgumentOverlayView: UIButton {
  var characterRange:NSRange! //represents the character range this view is over
  var editorTextViewController:EditorTextViewController!
  
  func setupView(levelName:String, functionName:String) {
    backgroundColor = UIColor.redColor()
    //round the corners
    layer.cornerRadius = 10
    layer.masksToBounds = true
    if levelName == "true-names" {
      setupTrueNames()
    }
    addTarget(self, action: Selector("onTapped"), forControlEvents: .TouchUpInside)
  }
  
  func setupTrueNames() {
    //only function is attack
    let defaultLabel = UILabel(frame: CGRect(x: 0, y: editorTextViewController.textView.lineSpacing, width: 0, height: 0))
    defaultLabel.text = "\"Brak\""
    defaultLabel.font = editorTextViewController.currentFont!
    defaultLabel.sizeToFit()
    addSubview(defaultLabel)
  }
  
  func resetLocationToCurrentCharacterRange() {
    let glyphRange = editorTextViewController.layoutManager.glyphRangeForCharacterRange(characterRange, actualCharacterRange: nil)
    var boundingRect = editorTextViewController.layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: editorTextViewController.textContainer)
    boundingRect.origin.y += editorTextViewController.textView.lineSpacing
    frame = boundingRect
    setNeedsDisplay()
  }
  
  func onTapped() {
    //create the view here
    let choices = ["\"Brak\"","\"Treg\""]
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
