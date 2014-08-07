//
//  Editor.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

class Editor : NSObject, UITextViewDelegate {
  var textView:EditorTextView 
  
  init(textView:EditorTextView) {
    self.textView = textView
    super.init()
  }

  func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
    if text == "\n" {
      textView.setNeedsDisplay()
    }
    return true
  }

}
