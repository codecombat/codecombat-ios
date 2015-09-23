//
//  EditorInputAccessoryView.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 10/25/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class EditorInputAccessoryView:UIView {
  var parentTextView:UITextView!
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.grayColor()
    //Create the buttons
    let buttonSpacing = 10
    let buttonYOffset = 5
    let buttonHeight = 45
    let selLeftFrame = CGRect(x: buttonSpacing, y: buttonYOffset, width: 100, height: buttonHeight)
    let expandSelectionLeftButton = UIButton(frame: selLeftFrame)
    expandSelectionLeftButton.setTitle("SelLeft", forState: UIControlState.Normal)
    expandSelectionLeftButton.addTarget(parentTextView, action: Selector("expandSelectionLeft"), forControlEvents: UIControlEvents.TouchUpInside)
    
    let selRightFrame = CGRect(
      x: buttonSpacing + Int(selLeftFrame.origin.x + selLeftFrame.width),
      y: buttonYOffset,
      width: 100,
      height: buttonHeight)
    let expandSelectionRightButton = UIButton(frame: selRightFrame)
    expandSelectionRightButton.setTitle("SelRight", forState: UIControlState.Normal)
    expandSelectionRightButton.addTarget(parentTextView, action: Selector("expandSelectionRight"), forControlEvents: UIControlEvents.TouchUpInside)
    
    let cursorLeftFrame = CGRect(
      x: buttonSpacing + Int(selRightFrame.origin.x + selRightFrame.width),
      y: buttonYOffset,
      width: 100,
      height: buttonHeight)
    let cursorLeftButton = UIButton(frame: cursorLeftFrame)
    cursorLeftButton.setTitle("CurLeft", forState: UIControlState.Normal)
    cursorLeftButton.addTarget(parentTextView, action: Selector("moveCursorLeft"), forControlEvents: UIControlEvents.TouchUpInside)
    
    let cursorRightFrame = CGRect(
      x: buttonSpacing + Int(cursorLeftFrame.origin.x + cursorLeftFrame.width),
      y: buttonYOffset,
      width: 100,
      height: buttonHeight)
    let cursorRightButton = UIButton(frame: cursorRightFrame)
    cursorRightButton.setTitle("CurRight", forState: UIControlState.Normal)
    cursorRightButton.addTarget(parentTextView, action: Selector("moveCursorRight"), forControlEvents: UIControlEvents.TouchUpInside)
    addSubview(expandSelectionLeftButton)
    addSubview(expandSelectionRightButton)
    addSubview(cursorLeftButton)
    addSubview(cursorRightButton)
  }
  
  func expandSelectionLeft() {
    if parentTextView.selectedRange.location > 0 {
      parentTextView.selectedRange.location--
      parentTextView.selectedRange.length++
    }
  }
  
  func expandSelectionRight() {
    if parentTextView.selectedRange.location < parentTextView.textStorage.length {
      parentTextView.selectedRange.length++
    }
  }
  
  func moveCursorLeft() {
    if parentTextView.selectedRange.location > 0 {
      parentTextView.selectedRange.location--
    }
  }
  
  func moveCursorRight() {
    if parentTextView.selectedRange.location < parentTextView.textStorage.length {
      parentTextView.selectedRange.location++
      if parentTextView.selectedRange.length > 0 {
        parentTextView.selectedRange.length--
      }
    }
  }
}