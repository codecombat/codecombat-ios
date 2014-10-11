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
  
  
  override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [NSObject : AnyObject] {
    var attributes = attributedString!.attributesAtIndex(location, effectiveRange: range)
    return attributes
  }
  
  func scopeToAttributes(scopeName:String) -> [NSObject : AnyObject]? {
    let scopes = scopeName.componentsSeparatedByString(" ")
    if contains(scopes, "comment") {
      return [NSForegroundColorAttributeName:UIColor.redColor()]
    }
    return nil
  }
  
  override func replaceCharactersInRange(range: NSRange, withString str: String) {
    let previousContents = string()!.substringWithRange(range)
    var newRange = range
    newRange.length = NSString(string: str).length
    undoManager.prepareWithInvocationTarget(self).replaceCharactersInRange(newRange, withString: previousContents)
    attributedString!.replaceCharactersInRange(range, withString: str)
    //find a more efficient way of getting string length that isn't buggy
    let changeInLength:NSInteger = (NSString(string: str).length - range.length)
    self.edited(NSTextStorageEditActions.EditedCharacters,
      range: range,
      changeInLength: changeInLength)
  }
  
  private func sendTextEditedNotification() {
    let nc = NSNotificationCenter.defaultCenter()
    nc.postNotificationName("textEdited", object: nil)
  }
  
  override func setAttributes(attrs: [NSObject : AnyObject]!, range: NSRange) {
    attributedString!.setAttributes(attrs, range: range)
    self.edited(NSTextStorageEditActions.EditedAttributes,
      range: range,
      changeInLength: 0)
  }
  
  func sendOverlayRequest(metaFunctionCallNode:DocumentNode) {
    /*println("Function name: \(metaFunctionCallNode.children[0].data)")
    println("Open bracket: \(metaFunctionCallNode.children[1].children[0].data)")
    println("Close bracket:\(metaFunctionCallNode.children[1].data)")*/
  }
  
  override func processEditing() {
    super.processEditing()
    
    //NSNotificationCenter.defaultCenter().postNotificationName("eraseParameterBoxes", object: nil, userInfo: nil)
    let parser = LanguageParser(scope: language, data: attributedString!.string, provider: languageProvider)
    highlighter = NodeHighlighter(parser: parser)
    //the most inefficient way of doing this, optimize later
    let documentRange = NSRange(location: 0, length: string()!.length)
    println("Edited range loc: \(editedRange.location), length: \(editedRange.length)")
    println("Document range loc: \(documentRange.location), length: \(documentRange.length)")
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
        if scope.hasPrefix("meta.function-call.python") {
          sendOverlayRequest(highlighter.lastScopeNode)
        }
        
      }
    }
    sendTextEditedNotification()
  }
}
