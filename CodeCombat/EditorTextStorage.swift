//
//  editorTextStorage.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/28/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

//Thank you http://www.objc.io/issue-5/getting-to-know-textkit.html

class EditorTextStorage: NSTextStorage {
  var attributedString:NSMutableAttributedString?
  var languageProvider = LanguageProvider()
  var highlighter:NodeHighlighter!
  let language = "python"
  let undoManager = NSUndoManager()
  var nestedEditingLevel = 0
  
  override init() {
    super.init()
    attributedString = NSMutableAttributedString()
    let parser = LanguageParser(scope: language, data: attributedString!.string, provider: languageProvider)
    highlighter = NodeHighlighter(parser: parser)
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func string() -> NSString? {
    return attributedString!.string
  }
  
  override func beginEditing() {
    nestedEditingLevel++
    super.beginEditing()
  }
  override func endEditing() {
    super.endEditing()
    //If you need to do things which require laying out glyphs, do them here. If you trigger them
    //before, you'll crash.
    if nestedEditingLevel == 1 {
      NSNotificationCenter.defaultCenter().postNotificationName("textStorageFinishedTopLevelEditing", object: nil)
      highlightSyntax()
    }
    nestedEditingLevel--
  }
  
  func findArgumentOverlays() -> [String:NSRange] {
    var argumentOverlays:[String:NSRange] = [:]
    let documentRange = NSRange(location: 0, length: string()!.length)
    
    for var charIndex = documentRange.location; charIndex < NSMaxRange(documentRange); charIndex++ {
      let scopeName = highlighter.scopeName(charIndex)
      let scopes = scopeName.componentsSeparatedByString(" ")
      for scope in scopes {
        let scopeExtent = highlighter.scopeExtent(charIndex)
        if scopeExtent == nil {
          continue
        }
        //Identify the function name here
        if scope.hasPrefix("codecombat.arguments") {
          //go past the ( and into the function name
          let parentScopeName = highlighter.scopeName(charIndex - 2)
          var functionName = "unsetForLanguage\(language)"
          if language == "python" {
            let parentNode = highlighter.lastScopeNode
            functionName = parentNode.data
          }
          argumentOverlays[functionName] = scopeExtent!
          charIndex = NSMaxRange(scopeExtent!)
        }
      }
    }
    return argumentOverlays
  }
  
  func highlightSyntax() {
    let parser = LanguageParser(scope: language, data: attributedString!.string, provider: languageProvider)
    highlighter = NodeHighlighter(parser: parser)
    //the most inefficient way of doing this, optimize later
    let documentRange = NSRange(location: 0, length: string()!.length)
    
    self.removeAttribute(NSForegroundColorAttributeName, range: documentRange)
    for var charIndex = documentRange.location; charIndex < NSMaxRange(documentRange); charIndex++ {
      let scopeName = highlighter.scopeName(charIndex)
      let scopes = scopeName.componentsSeparatedByString(" ")
      for scope in scopes {
        let scopeExtent = highlighter.scopeExtent(charIndex)
        if scopeExtent == nil {
          continue
        }
        if scope.hasPrefix("comment") {
          addAttribute(NSForegroundColorAttributeName, value: UIColor.grayColor(), range: scopeExtent!)
          charIndex = NSMaxRange(scopeExtent!)
        } else if scope.hasPrefix("meta.function-call.generic") { //function calls
          addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: scopeExtent!)
          charIndex = NSMaxRange(scopeExtent!)
        } else if scope.hasPrefix("variable.language") && highlighter.lastScopeNode.data == "self" { //python self
          addAttribute(NSForegroundColorAttributeName, value: UIColor.purpleColor(), range: scopeExtent!)
          charIndex = NSMaxRange(scopeExtent!)
        }
      }
    }
    
  }
  
  override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [NSObject : AnyObject] {
    var attributes = attributedString!.attributesAtIndex(location, effectiveRange: range)
    return attributes
  }
  
  override func replaceCharactersInRange(range: NSRange, withString str: String) {
    let previousContents = attributedString?.attributedSubstringFromRange(range)
    var newRange = range
    newRange.length = NSString(string: str).length
    undoManager.prepareWithInvocationTarget(self).replaceCharactersInRange(newRange, withAttributedString: previousContents!)
    beginEditing()
    attributedString!.replaceCharactersInRange(range, withString: str)
    let changeInLength:NSInteger = (NSString(string: str).length - range.length)
    self.edited(NSTextStorageEditActions.EditedCharacters,
      range: range,
      changeInLength: changeInLength)
    endEditing()
  }
  
  override func replaceCharactersInRange(range: NSRange, withAttributedString attrString: NSAttributedString) {
    let previousContents = attributedString?.attributedSubstringFromRange(range)
    var newRange = range
    newRange.length = NSString(string: attrString.string).length
    undoManager.prepareWithInvocationTarget(self).replaceCharactersInRange(newRange, withAttributedString: previousContents!)
    beginEditing()
    attributedString!.replaceCharactersInRange(range, withAttributedString: attrString)
    let changeInLength:NSInteger = (NSString(string: attrString.string).length - range.length)
    self.edited(NSTextStorageEditActions.EditedCharacters,
      range: range,
      changeInLength: changeInLength)
    endEditing()
  }
  
  override func processEditing() {
    super.processEditing()
    NSNotificationCenter.defaultCenter().postNotificationName("textEdited", object: nil)
  }
  
  
  override func setAttributes(attrs: [NSObject : AnyObject]!, range: NSRange) {
    attributedString!.setAttributes(attrs, range: range)
    self.edited(NSTextStorageEditActions.EditedAttributes,
      range: range,
      changeInLength: 0)
  }
}
