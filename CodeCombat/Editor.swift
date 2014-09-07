//
//  Editor.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

class Editor : NSObject, UITextViewDelegate {
  var textView:EditorTextView
  var currentLanguage:String = "javascript"
  
  init(textView:EditorTextView) {
    self.textView = textView
    //230	212	145
    textView.backgroundColor = UIColor(
      red: CGFloat(230.0 / 256.0),
      green: CGFloat(212.0 / 256.0),
      blue: CGFloat(145.0 / 256.0),
      alpha: 1)
    super.init()
  }

  func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
    if text == "\n" {
      textView.setNeedsDisplay()
    }
    return true
  }
  
  func textViewDidChange(textView: UITextView!) {
    self.textView.resizeLineNumberGutter()
  }
}
