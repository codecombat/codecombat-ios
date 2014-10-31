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
  var functionName = ""
  var defaultContentsToInsertOnRun = ""
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  init(frame: CGRect, textViewController:EditorTextViewController, characterRange:NSRange, functionName:String) {
    super.init(frame: frame)
    
    editorTextViewController = textViewController
    self.characterRange = characterRange
    self.functionName = functionName
    
    customizeViewAppearance()
    setupDefaultLabel()
    resetLocationToCurrentCharacterRange()
    
    addTarget(self, action: Selector("onTapped"), forControlEvents: .TouchUpInside)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onCodeRun"), name: "codeRun", object: nil)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  func onCodeRun() {
    stringWasSelectedByStringPickerPopover(defaultContentsToInsertOnRun)
  }
  
  func onTapped() {
    switch LevelSettingsManager.sharedInstance.level {
    case .TrueNames:
      makeStringChoicePopoverWithChoices(["\"Brak\"","\"Treg\""])
    case .TheRaisedSword:
      makeStringChoicePopoverWithChoices(["\"Gurt\"","\"Rig\"","\"Ack\""])
    case .NewSight:
      makeStringChoicePopoverWithChoices(["\"Door\""])
    default:
      break
    }
  }
  
  internal func stringWasSelectedByStringPickerPopover(selected:String) {
    editorTextViewController.replaceCharactersInCharacterRange(characterRange, str: selected)
    self.hidden = true
  }
  
  private func customizeViewAppearance() {
    backgroundColor = UIColor.redColor()
    layer.cornerRadius = 10
    layer.masksToBounds = true
  }
  
  private func setupDefaultLabel() {
    switch LevelSettingsManager.sharedInstance.level {
    case .TrueNames:
      addSubview(makeDefaultLabelWithText("\"Brak\""))
    case .TheRaisedSword:
      addSubview(makeDefaultLabelWithText("\"Gurt\""))
    case .NewSight:
      addSubview(makeDefaultLabelWithText("\"Door\""))
    default:
      break
    }
  }
  
  private func makeStringChoicePopoverWithChoices(choices:[String]) {
    editorTextViewController.createStringPickerPopoverWithChoices(choices,
      characterRange: characterRange,
      delegate: self)
  }
  
  private func resetLocationToCurrentCharacterRange() {
    let glyphRange = editorTextViewController.layoutManager.glyphRangeForCharacterRange(characterRange, actualCharacterRange: nil)
    var boundingRect = editorTextViewController.layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: editorTextViewController.textContainer)
    boundingRect.origin.y += editorTextViewController.textView.lineSpacing
    frame = boundingRect
    setNeedsDisplay()
  }
  
  private func makeDefaultLabelWithText(text:String) -> UILabel {
    let defaultLabel = UILabel(frame: CGRect(x: 0, y: editorTextViewController.textView.lineSpacing, width: 0, height: 0))
    defaultLabel.text = text
    defaultLabel.font = editorTextViewController.currentFont!
    defaultLabel.sizeToFit()
    defaultContentsToInsertOnRun = text
    return defaultLabel
  }

  
  
}
