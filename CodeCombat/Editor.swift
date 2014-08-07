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
  
  func textViewDidChange(textView: UITextView!) {
    textView.setNeedsDisplay()
  }

}
