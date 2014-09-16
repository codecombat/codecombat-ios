//
//  EditorTextViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 9/15/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class EditorTextViewController: UIViewController, UITextViewDelegate {
  let textStorage = EditorTextStorage()
  let layoutManager = NSLayoutManager()
  let textContainer = NSTextContainer()
  let currentFont = UIFont(name: "Courier", size: 22)
  var textView:EditorTextView! {
    didSet {
      textView.delegate = self
      textView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
      textView.selectable = true
      textView.editable = true
      textView.font = currentFont
      textView.showLineNumbers()
      textView.backgroundColor = UIColor(
        red: CGFloat(230.0 / 256.0),
        green: CGFloat(212.0 / 256.0),
        blue: CGFloat(145.0 / 256.0),
        alpha: 1)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func createTextViewWithFrame(frame:CGRect) {
    setupTextKitHierarchy()
    textView = EditorTextView(frame: frame, textContainer: textContainer)
    setupNotificationCenterObservers()
  }
  
  private func setupTextKitHierarchy() {
    layoutManager.allowsNonContiguousLayout = true
    textStorage.addLayoutManager(layoutManager)
    textContainer.lineBreakMode = NSLineBreakMode.ByWordWrapping
    textContainer.widthTracksTextView = true
    layoutManager.addTextContainer(textContainer)
  }

  private func setupNotificationCenterObservers() {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleDrawParameterRequest:"), name: "drawParameterBox", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleEraseParameterViewsRequest:"), name: "eraseParameterBoxes", object: nil)
  }
  
  func handleEraseParameterViewsRequest(notification:NSNotification) {
    textView.eraseParameterViews()
  }
  
  func handleDrawParameterRequest(notification:NSNotification) {
    return
    let info = notification.userInfo!
    let functionName:NSString? = info["functionName"] as? NSString
    let range:NSRange = (info["rangeValue"] as? NSValue)!.rangeValue
    println("Should be drawing a box for func \(functionName!)")
    textView.drawParameterOverlay(range)
  }
  
  private func resetFontToCurrentFont() {
    textView.font = currentFont
  }
  
  func replaceTextViewContentsWithString(text:String) {
    textStorage.replaceCharactersInRange(NSRange(location: 0, length: 0), withString: text)
    resetFontToCurrentFont()
    textView.setNeedsDisplay()
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
