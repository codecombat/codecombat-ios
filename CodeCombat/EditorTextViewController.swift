//
//  EditorTextViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 9/15/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class EditorTextViewController: UIViewController, UITextViewDelegate, NSLayoutManagerDelegate, UIGestureRecognizerDelegate {
  let textStorage = EditorTextStorage()
  let layoutManager = NSLayoutManager()
  let textContainer = NSTextContainer()
  var draggedLabel:UILabel!
  var draggedCharacterRange:NSRange!
  var coverTextView:UIView!
  var deleteOverlayView:UIView!
  let deleteOverlayWidth:CGFloat = 75
  var dragGestureRecognizer:UIPanGestureRecognizer!
  let currentFont = UIFont(name: "Courier", size: 22)
  var textView:EditorTextView! {
    didSet {
      textView.delegate = self
      textView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
      textView.selectable = false
      textView.editable = false
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
    //view.addGestureRecognizer(dragGestureRecognizer)
    // Do any additional setup after loading the view.
    dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handleDrag:")
    dragGestureRecognizer.delegate = self
    
    
  }
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  private func createDeleteOverlayView() -> UIView {
    var deleteOverlayFrame = self.textView.frame
    deleteOverlayFrame.origin.x = deleteOverlayFrame.width - deleteOverlayWidth
    deleteOverlayFrame.size.width = deleteOverlayWidth
    
    let overlay = UIView(frame: deleteOverlayFrame)
    overlay.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.3)
    return overlay
  }
  
  func handleDrag(recognizer:UIPanGestureRecognizer) {
    if recognizer == textView.panGestureRecognizer {
      return
    }
    //get glyph under point
    var locationInParentView = recognizer.locationInView(parentViewController!.view)
    locationInParentView.y += (textView.lineSpacing + textView.font.lineHeight) / 2
    let dragLocation = recognizer.locationInView(self.textView)
    
    switch recognizer.state {
    case .Began:
      let nearestGlyphIndexToDrag = layoutManager.glyphIndexForPoint(dragLocation, inTextContainer: textContainer)
      var effectiveGlyphRange:NSRange = NSRange(location:0, length:0)
      var lineFragmentRectToDrag = layoutManager.lineFragmentRectForGlyphAtIndex(nearestGlyphIndexToDrag, effectiveRange: &effectiveGlyphRange)
      let glyphRange = layoutManager.glyphRangeForBoundingRect(lineFragmentRectToDrag, inTextContainer: textContainer)
      let characterRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
      println("Dragging character range loc:\(glyphRange.location), len: \(glyphRange.length)")
      let attributedSubstring = textStorage.attributedString!.attributedSubstringFromRange(characterRange)
      //make a new subview
      //cover the text
      draggedLabel = UILabel(frame: lineFragmentRectToDrag)
      draggedLabel.attributedText = attributedSubstring
      draggedLabel.sizeToFit()
      draggedLabel.center = locationInParentView
      draggedCharacterRange = characterRange
      //cover the text
      lineFragmentRectToDrag.size.height = textView.font.lineHeight + textView.lineSpacing
      lineFragmentRectToDrag.origin.y += textView.lineSpacing
      coverTextView = UIView(frame: lineFragmentRectToDrag)
      coverTextView.backgroundColor = textView.backgroundColor
      //coverTextView.center = dragLocation
      textView.addSubview(coverTextView)
      parentViewController!.view.addSubview(draggedLabel)
      deleteOverlayView = createDeleteOverlayView()
      deleteOverlayView.hidden = true
      textView.addSubview(deleteOverlayView)
      
      break
    case .Changed:
      draggedLabel.center = locationInParentView
      if draggedLabel.center.x > parentViewController!.view.bounds.maxX - deleteOverlayWidth {
        deleteOverlayView.hidden = false
      } else {
        deleteOverlayView.hidden = true
      }
      break
    case .Ended:
      var shouldDelete = false
      if draggedLabel.center.x > parentViewController!.view.bounds.maxX - deleteOverlayWidth {
        textStorage.beginEditing()
        if draggedCharacterRange.location != 0 {
          textStorage.replaceCharactersInRange(draggedCharacterRange, withString: "")
        } else {
          textStorage.replaceCharactersInRange(draggedCharacterRange, withString: "\n")
        }
        
        textStorage.endEditing()
        textView.setNeedsDisplay()
      }
      deleteOverlayView.removeFromSuperview()
      deleteOverlayView = nil
      coverTextView.removeFromSuperview()
      coverTextView = nil
      draggedLabel.removeFromSuperview()
      draggedLabel = nil
      
      break
    default:
      break
    }
  }
  
  
  func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    if draggedLabel != nil {
      return false
    }
    //find if the nearest glyph is a newline (aka not dragging on a thing)
    let nearestGlyphIndexToDrag = layoutManager.glyphIndexForPoint(gestureRecognizer.locationInView(textView), inTextContainer: textContainer)
    let characterIndex = layoutManager.characterIndexForGlyphAtIndex(nearestGlyphIndexToDrag)
    let character = textStorage.string()!.characterAtIndex(characterIndex)
    if character == 10 {
      return false
    }
    return true
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func createTextViewWithFrame(frame:CGRect) {
    setupTextKitHierarchy()
    textView = EditorTextView(frame: frame, textContainer: textContainer)
    textView.addGestureRecognizer(dragGestureRecognizer)
    textView.panGestureRecognizer.requireGestureRecognizerToFail(dragGestureRecognizer)
    view.addSubview(textView)
    
    setupNotificationCenterObservers()
  }
  
  private func setupTextKitHierarchy() {
    layoutManager.allowsNonContiguousLayout = true
    layoutManager.delegate = self
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
  
  func layoutManager(layoutManager: NSLayoutManager, lineSpacingAfterGlyphAtIndex glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
    return textView.lineSpacing
  }
}
