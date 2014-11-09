//
//  EditorTextView.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class GutterProblemLineAnnotationButton: UIButton {
  var problemDescription:String = ""
}

class EditorTextView: UITextView, NSLayoutManagerDelegate {
  var parentTextViewController:EditorTextViewController!
  var shouldShowLineNumbers = false
  var numberOfCharactersInLineNumberGutter = 0
  var lineNumberWidth = CGFloat(20.0)
  let deletionOverlayWidth:CGFloat = 75
  var deletionOverlayView:UIView?
  var currentDragView:UIView? = nil
  var currentDragHintView:ParticleView?
  var lineDimmingOverlay:UIView? = nil
  var currentLineHighlightingView:UIView? = nil
  var errorMessageView:UILabel? = nil
  var currentProblemGutterLineAnnotations:[Int:GutterProblemLineAnnotationButton] = [:]
  var currentProblemLineHighlights:[Int:UIView] = [:]
  var overlayLocationToViewMap:[Int:ArgumentOverlayView] = [:]
  var dragOverlayLabels:[Int:UILabel] = Dictionary<Int,UILabel>()
  var originalDragOverlayLabelOffsets:[Int:CGFloat] = Dictionary<Int,CGFloat>()
  var draggedLineNumber = -1
  var defaultFont = UIFont(name: "Menlo", size: 20)
  let gutterPadding = CGFloat(5.0)
  var gutterWidth:CGFloat = 0
  let lineSpacing:CGFloat = 5
  var accessoryView:UIView?
  var keyboardModeEnabled:Bool {
    return editable && selectable
  }
  override var inputAccessoryView: UIView? {
    get {
      if self.accessoryView == nil {
        let accessoryViewFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: 55)
        let accessory = EditorInputAccessoryView(frame: accessoryViewFrame)
        accessory.parentTextView = self
        self.accessoryView = accessory
      }
      return self.accessoryView
    }
    set {
      self.accessoryView = newValue
    }
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    autocorrectionType = UITextAutocorrectionType.No
    autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    selectable = false
    editable = false
    //Not sure if this will get reset, if it does it will cause bugs
    font = defaultFont
    gutterWidth = lineNumberWidth + 4
    showLineNumbers()
    backgroundColor = UIColor.clearColor()
    layoutManager.delegate = self
  }
  
  override func drawRect(rect: CGRect) {
    if shouldShowLineNumbers {
      drawLineNumberBackground()
      drawLineNumbers(rect)
    }
    super.drawRect(rect)
  }
  
  //LayoutManager delegate functions
  func layoutManager(layoutManager: NSLayoutManager, lineSpacingAfterGlyphAtIndex glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
    return lineSpacing
  }
  
  func layoutManager(layoutManager: NSLayoutManager, didCompleteLayoutForTextContainer textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
    processOverlayRequests(parentTextViewController.getArgumentOverlays())
  }
  
  //Deletion overlay functions
  func createDeletionOverlayView() {
    var deleteOverlayFrame = frame
    deleteOverlayFrame.origin.y = 0
    deleteOverlayFrame.origin.x = deleteOverlayFrame.width - deletionOverlayWidth
    deleteOverlayFrame.size.width = deletionOverlayWidth
    
    let overlay = UIView(frame: deleteOverlayFrame)
    overlay.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.3)
    deletionOverlayView = overlay
    deletionOverlayView!.hidden = true
    addSubview(deletionOverlayView!)
  }
  
  func hideDeletionOverlayView() {
    deletionOverlayView?.hidden = true
  }
  
  func showDeletionOverlayView() {
    deletionOverlayView?.hidden = false
  }
  
  func removeDeletionOverlayView() {
    deletionOverlayView?.removeFromSuperview()
    deletionOverlayView = nil
  }
  
  
  func characterIndexAtPoint(point:CGPoint) -> Int{
    return layoutManager.characterIndexForPoint(point, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
  }
  
  func toggleKeyboardMode() {
    if keyboardModeEnabled {
      editable = false
      selectable = false
      resignFirstResponder()
    } else {
      editable = true
      selectable = true
      becomeFirstResponder()
    }
  }
  
  private func processOverlayRequests(requestedOverlayFunctionNamesAndRanges:[(String, NSRange)]) {
    removeAllOverlaysNotRequested(requestedOverlayFunctionNamesAndRanges)
    for (functionName,overlayRange) in requestedOverlayFunctionNamesAndRanges {
      //if view already exists and is requested, don't redraw
      if overlayLocationToViewMap.indexForKey(overlayRange.location) != nil {
        continue
      }
      let range = overlayRange
      let defaultRect = CGRect()
      let newView = ArgumentOverlayView(
        frame: defaultRect,
        textViewController: parentTextViewController,
        characterRange: overlayRange,
        functionName: functionName)
      
      overlayLocationToViewMap[range.location] = newView
      addSubview(newView)
    }
  }
  
  private func removeAllOverlaysNotRequested(requestedOverlayFunctionNamesAndRanges:[(String, NSRange)]) {
    let overlayRequestLocations = requestedOverlayFunctionNamesAndRanges.map({$0.1.location})
    var keysToRemove:[Int] = []
    for (overlayLocation, overlay) in overlayLocationToViewMap {
      if !contains(overlayRequestLocations, overlayLocation) {
        overlay.removeFromSuperview()
        keysToRemove.append(overlayLocation)
      }
    }
    for key in keysToRemove {
      overlayLocationToViewMap.removeValueForKey(key)
    }
  }
  
  func drawDragHintViewOnLastLine() {
    let glyphRange = layoutManager.glyphRangeForTextContainer(textContainer)
    var lastLineFragmentRect = layoutManager.lineFragmentRectForGlyphAtIndex(NSMaxRange(glyphRange) - 1, effectiveRange: nil)
    let bufferHeight = 100
    let lineHeight = font.lineHeight + lineSpacing
    lastLineFragmentRect.origin.y += lineHeight + lineSpacing - CGFloat(bufferHeight/2)
    lastLineFragmentRect.size.height = lineHeight + CGFloat(bufferHeight)
    currentDragHintView = ParticleView(frame: lastLineFragmentRect)
    addSubview(currentDragHintView!)
  }
  
  func removeDragHintView() {
    currentDragHintView?.removeFromSuperview()
    currentDragHintView = nil
  }
  
  func slightlyHighlightLineUnderLocation(location:CGPoint) {
    let lineNumber = lineNumberUnderPoint(location)
    let FirstLineNumberRect = boundingRectForLineNumber(lineNumber)
    let LineHeight = font.lineHeight + lineSpacing
    let HighlightingRect = CGRect(
      x: FirstLineNumberRect.origin.x,
      y: FirstLineNumberRect.origin.y,
      width: FirstLineNumberRect.width,
      height: FirstLineNumberRect.height)
    if lineDimmingOverlay == nil {
      lineDimmingOverlay = UIView(frame: HighlightingRect)
      lineDimmingOverlay?.backgroundColor = UIColor(
        red: 1,
        green: 1,
        blue: 1,
        alpha: 0.3)
      addSubview(lineDimmingOverlay!)
    }
    lineDimmingOverlay?.frame = HighlightingRect
  }
  
  func removeLineDimmingOverlay() {
    lineDimmingOverlay?.removeFromSuperview()
    lineDimmingOverlay = nil
  }
  
  func highlightLineNumber(lineNumber:Int) {
    removeCurrentLineNumberHighlight()
    var lineFragmentFrame = boundingRectForLineNumber(lineNumber)
    lineFragmentFrame.origin.y += lineSpacing
    currentLineHighlightingView = UIView(frame:lineFragmentFrame )
    currentLineHighlightingView!.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.3)
    addSubview(currentLineHighlightingView!)
  }
  
  func removeCurrentLineNumberHighlight() {
    currentLineHighlightingView?.removeFromSuperview()
    currentLineHighlightingView = nil
  }
  
  func highlightUserCodeProblemLine(lineNumber:Int) {
    if let problemLineHighlight = currentProblemLineHighlights[lineNumber] {
      
    } else {
      var frame = boundingRectForLineNumber(lineNumber)
      frame.origin.y += lineSpacing
      let highlightView = UIView(frame: frame)
      highlightView.backgroundColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.3)
      currentProblemLineHighlights[lineNumber] = highlightView
      addSubview(highlightView)
      sendSubviewToBack(highlightView)
    }
  }
  
  func removeUserCodeProblemLineHighlights() {
    for (line, view) in currentProblemLineHighlights {
      view.removeFromSuperview()
    }
    currentProblemLineHighlights.removeAll(keepCapacity: true)
  }
  
  
  func addUserCodeProblemGutterAnnotationOnLine(lineNumber:Int, message:String) {
    if let problemView = currentProblemGutterLineAnnotations[lineNumber] {
      //Just leave it
    } else {
      //place the image here
      var frame = boundingRectForLineNumber(lineNumber)
      frame.origin.x = 0
      frame.size.width = lineNumberWidth
      frame.size.width = lineSpacing + font.lineHeight
      frame.origin.y += lineSpacing
      let annotationImage = UIImage(named: "editorSidebarErrorIcon")
      let gutterAnnotation = GutterProblemLineAnnotationButton(frame: frame)
      gutterAnnotation.setImage(annotationImage, forState: UIControlState.Normal)
      gutterAnnotation.problemDescription = message
      gutterAnnotation.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
      gutterAnnotation.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
      gutterAnnotation.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
      gutterAnnotation.frame = frame
      gutterAnnotation.imageView!.frame = frame
      gutterAnnotation.addTarget(self, action: Selector("displayProblemErrorMessageFromView:"), forControlEvents: UIControlEvents.TouchUpInside)
      gutterAnnotation.userInteractionEnabled = true
      currentProblemGutterLineAnnotations[lineNumber] = gutterAnnotation
      addSubview(gutterAnnotation)
      gutterAnnotation.setNeedsLayout()
      gutterAnnotation.setNeedsDisplay()
    }
  }
  
  func displayProblemErrorMessageFromView(sender:GutterProblemLineAnnotationButton) {
    println("DISPLAYING!!")
    if errorMessageView == nil {
      let backgroundImage = UIImage(named: "editorErrorBackground")!
      let mainScreenView = superview!.superview!
      var errorMessageFrame = mainScreenView.frame
      errorMessageFrame.origin.y = errorMessageFrame.height - 120
      errorMessageFrame.origin.x = errorMessageFrame.width - backgroundImage.size.width
      errorMessageFrame.size.width = backgroundImage.size.width
      errorMessageFrame.size.height = backgroundImage.size.height
      
      errorMessageView = UILabel(frame: errorMessageFrame)
      errorMessageView?.textAlignment = NSTextAlignment.Center
      errorMessageView?.opaque = false
      errorMessageView?.text = sender.problemDescription
      errorMessageView?.backgroundColor = UIColor(patternImage: backgroundImage)
      errorMessageView?.alpha = 0
      errorMessageView?.textColor = UIColor.whiteColor()
      mainScreenView.addSubview(errorMessageView!)
      UIView.animateWithDuration(0.5, animations: {
        self.errorMessageView!.alpha = 1
      })
    } else {
      //hide the display problem error message
      UIView.animateWithDuration(0.5, animations: { self.errorMessageView!.alpha = 0 }, completion: { (Bool) -> Void in
        self.clearErrorMessageView()
      })
    }
    
  }
  
  func clearErrorMessageView() {
    errorMessageView?.removeFromSuperview()
    errorMessageView = nil
  }
  
  func clearCodeProblemGutterAnnotations() {
    for (line, view) in currentProblemGutterLineAnnotations {
      view.removeFromSuperview()
    }
    currentProblemGutterLineAnnotations.removeAll(keepCapacity: true)
  }
  
  private func lineFragmentRectForLineNumber(targetLineNumber:Int) -> CGRect {
    let storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    
    let textRange = layoutManager.glyphRangeForTextContainer(textContainer)
    let glyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange,
      actualCharacterRange: nil)
    var numberOfLinesBeforeVisible = 0
    for var index = 0; index < textRange.location; numberOfLinesBeforeVisible++ {
      index = NSMaxRange(storage.string()!.lineRangeForRange(NSRange(location: index, length: 0)))
    }
    var lineNumber = numberOfLinesBeforeVisible
    let textAttributes = [NSFontAttributeName:font]
    var lineFragmentRect:CGRect = CGRect()
    func lineFragmentClosure(aRect:CGRect, aUsedRect:CGRect,
      textContainer:NSTextContainer!, glyphRange:NSRange,
      stop:UnsafeMutablePointer<ObjCBool>) -> Void {
        let charRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
        let paraRange = storage.string()!.paragraphRangeForRange(charRange)
        //To avoid drawing numbers on wrapped lines
        if charRange.location == paraRange.location {
          lineNumber++
          if targetLineNumber == lineNumber {
            lineFragmentRect = aUsedRect
          }
          let LineNumberString = NSString(string: "\(lineNumber)")
          let Size = LineNumberString.sizeWithAttributes(textAttributes)
          let Point = CGPointMake(lineNumberWidth - 4 - Size.width, aRect.origin.y + 8)
          LineNumberString.drawAtPoint(Point, withAttributes: textAttributes)
        }
    }
    layoutManager.enumerateLineFragmentsForGlyphRange(glyphsToShow,
      usingBlock: lineFragmentClosure)
    return lineFragmentRect
  }
  
  func numberOfLinesInDocument() -> Int {
    let storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    
    let textRange = layoutManager.glyphRangeForTextContainer(textContainer)
    let glyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange,
      actualCharacterRange: nil)
    
    var currentLineNumber = 0
    func lineFragmentClosure(aRect:CGRect, aUsedRect:CGRect,
      textContainer:NSTextContainer!, glyphRange:NSRange,
      stop:UnsafeMutablePointer<ObjCBool>) -> Void {
        let charRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
        let paraRange = storage.string()!.paragraphRangeForRange(charRange)
        if charRange.location == paraRange.location {
          currentLineNumber++
        }
    }
    layoutManager.enumerateLineFragmentsForGlyphRange(glyphsToShow,
      usingBlock: lineFragmentClosure)
    return currentLineNumber
  }
  
  func characterIndexForStartOfLine(lineNumber:Int) -> Int {
    let storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    
    let textRange = layoutManager.glyphRangeForTextContainer(textContainer)
    let glyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange,
      actualCharacterRange: nil)
    
    var characterIndex = -1
    var currentLineNumber = 0
    func lineFragmentClosure(aRect:CGRect, aUsedRect:CGRect,
      textContainer:NSTextContainer!, glyphRange:NSRange,
      stop:UnsafeMutablePointer<ObjCBool>) -> Void {
        let charRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
        let paraRange = storage.string()!.paragraphRangeForRange(charRange)
        if charRange.location == paraRange.location {
          currentLineNumber++
          if lineNumber == currentLineNumber {
            characterIndex = layoutManager.characterIndexForGlyphAtIndex(glyphRange.location)
            stop.initialize(true)
          }
        }
    }
    layoutManager.enumerateLineFragmentsForGlyphRange(glyphsToShow,
      usingBlock: lineFragmentClosure)
    if characterIndex == -1 {
      return storage.string()!.length
    } else {
      return characterIndex
    }
  }
  
  func paragraphRangeUnderLocation(loc:CGPoint) -> NSRange {
    /*let storage = textStorage as EditorTextStorage
    let nearestCharacterIndex = layoutManager.characterIndexForPoint(loc, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    return storage.string()!.paragraphRangeForRange(<#range: NSRange#>)*/
    return NSRange(location:0, length: 0)
  }
  
  func lineNumberUnderPoint(var point:CGPoint) -> Int {
    //point.y += lineSpacing
    let storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    
    let textRange = layoutManager.glyphRangeForTextContainer(textContainer)
    let glyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange,
      actualCharacterRange: nil)
    
    var currentLineNumber = 0
    var lineNumberToReturn = -1
    var numberOfExtraLines = 0
    func lineFragmentClosure(aRect:CGRect, aUsedRect:CGRect,
      textContainer:NSTextContainer!, glyphRange:NSRange,
      stop:UnsafeMutablePointer<ObjCBool>) -> Void {
        let charRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
        let paraRange = storage.string()!.paragraphRangeForRange(charRange)
        if charRange.location == paraRange.location {
          currentLineNumber++
        } else {
          numberOfExtraLines++
        }
        let startY = aUsedRect.origin.y
        if point.y >= startY && point.y < startY + aUsedRect.height {
          lineNumberToReturn = currentLineNumber
          stop.initialize(true)
        }
    }
    layoutManager.enumerateLineFragmentsForGlyphRange(glyphsToShow,
      usingBlock: lineFragmentClosure)
    if lineNumberToReturn == -1 {
      lineNumberToReturn = Int(point.y / (font.lineHeight + lineSpacing)) + 1 - numberOfExtraLines
    }
    return lineNumberToReturn
  }
  
  func boundingRectForLineNumber(lineNumber:Int) -> CGRect {
    //point.y += lineSpacing
    let storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    
    let textRange = layoutManager.glyphRangeForTextContainer(textContainer)
    let glyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange,
      actualCharacterRange: nil)
    
    var currentLineNumber = 0
    var boundingRect:CGRect?
    var numberOfExtraLines = 0
    var stoppedOnEnumeration = -1
    var totalEnumerations = 0
    
    func lineFragmentClosure(aRect:CGRect, aUsedRect:CGRect,
      textContainer:NSTextContainer!, glyphRange:NSRange,
      stop:UnsafeMutablePointer<ObjCBool>) -> Void {
        totalEnumerations++
        let charRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
        let paraRange = storage.string()!.paragraphRangeForRange(charRange)
        if charRange.location == paraRange.location {
          currentLineNumber++
          if currentLineNumber == lineNumber {
            boundingRect = layoutManager.boundingRectForGlyphRange(layoutManager.glyphRangeForCharacterRange(paraRange, actualCharacterRange: nil), inTextContainer: textContainer)
            boundingRect!.origin.x = 0
            boundingRect!.size.width = frame.width
            stoppedOnEnumeration = totalEnumerations
            //stop.initialize(true)
          }
        } else {
          if stoppedOnEnumeration != -1 {
            stoppedOnEnumeration++
          }
          var characterRangeString = storage.string()!.substringWithRange(charRange).stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
          if countElements(characterRangeString) > 0 {
            numberOfExtraLines++
          }
        }
        
    }
    layoutManager.enumerateLineFragmentsForGlyphRange(glyphsToShow,
      usingBlock: lineFragmentClosure)
    if  boundingRect == nil {
      let LineHeight = font.lineHeight + lineSpacing
      let LineNumberRect = CGRect(
        x: 0,
        y: LineHeight * CGFloat(lineNumber - 1 + numberOfExtraLines),
        width: frame.width,
        height: LineHeight)
      boundingRect = LineNumberRect
    }
    //This is to correct for a weird extra line that TextKit puts at the end
    if stoppedOnEnumeration == totalEnumerations {
      boundingRect!.size.height -= font.lineHeight
    }
    
    return boundingRect!
  }
  
  private func drawLineNumbers(rect:CGRect) {
    let storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    
    let textRange = layoutManager.glyphRangeForBoundingRect(rect,
      inTextContainer: textContainer)
    let glyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange,
      actualCharacterRange: nil)
    var numberOfLinesBeforeVisible = 0
    for var index = 0; index < textRange.location; numberOfLinesBeforeVisible++ {
      index = NSMaxRange(storage.string()!.lineRangeForRange(NSRange(location: index, length: 0)))
    }
    var lineNumber = numberOfLinesBeforeVisible
    let textAttributes = [NSFontAttributeName:font]
    
    func lineFragmentClosure(aRect:CGRect, aUsedRect:CGRect,
      textContainer:NSTextContainer!, glyphRange:NSRange,
      stop:UnsafeMutablePointer<ObjCBool>) -> Void {
        let charRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
        let paraRange = storage.string()!.paragraphRangeForRange(charRange)
        //To avoid drawing numbers on wrapped lines
        if charRange.location == paraRange.location {
          lineNumber++
          let LineNumberString = NSString(string: "\(lineNumber)")
          let Size = LineNumberString.sizeWithAttributes(textAttributes)
          let Point = CGPointMake(lineNumberWidth - 4 - Size.width, aRect.origin.y + 8)
          LineNumberString.drawAtPoint(Point, withAttributes: textAttributes)
        }
    }
    layoutManager.enumerateLineFragmentsForGlyphRange(glyphsToShow,
      usingBlock: lineFragmentClosure)
  }
  
  //Draws a faint right border line alongside the line numbers–actually a few pixels past them
  private func drawLineNumberBackground() {
    let context = UIGraphicsGetCurrentContext()
    let LineNumberBackgroundColor = ColorManager.sharedInstance.gutterBorder
    CGContextSetFillColorWithColor(context, LineNumberBackgroundColor.CGColor)
    let LineNumberBackgroundRect = CGRect(
      x: bounds.origin.x + gutterWidth,
      y: bounds.origin.y + 5,
      width: 1,
      height: bounds.size.height - 50)
    CGContextFillRect(context, LineNumberBackgroundRect)
  }
  
  func pointIsInLineNumberGutter(point:CGPoint) -> Bool {
    return point.x < gutterWidth
  }
  
  private func showLineNumbers() {
    if shouldShowLineNumbers {
      return
    }
    font = defaultFont
    contentSize = CGSize(
      width: bounds.size.width - lineNumberWidth,
      height: bounds.size.height)
    shouldShowLineNumbers = true
    resizeLineNumberGutter()
  }
  
  func resizeLineNumberGutter() {
    if !shouldShowLineNumbers {
      return
    }
    let TotalLines = 10 //Replace this with the actual total lines
    let TotalLinesString = NSString(string: "\(TotalLines)")
    let NumberOfCharacters = TotalLinesString.length
    if NumberOfCharacters != numberOfCharactersInLineNumberGutter {
      let Size = TotalLinesString.sizeWithAttributes([NSFontAttributeName: font])
      let ContainerRect = bounds
      let Rect = CGRect(
        x: ContainerRect.origin.x,
        y: ContainerRect.origin.y,
        width: Size.width + gutterPadding,
        height: CGFloat.max)
      lineNumberWidth = Rect.size.width
      let exclusionRect = CGRect(x: Rect.origin.x, y: Rect.origin.y, width: Rect.size.width + 20, height: Rect.size.height)
      textContainer.exclusionPaths = [UIBezierPath(rect: exclusionRect)]
      numberOfCharactersInLineNumberGutter = NumberOfCharacters
    }
    setNeedsDisplay()
  }
  
  func createViewsForAllLinesExceptDragged(draggedLineFragmentRect:CGRect, draggedCharacterRange:NSRange) {
    let entireCharacterRange = layoutManager.glyphRangeForTextContainer(textContainer)
    let visibleGlyphs = layoutManager.glyphRangeForCharacterRange(entireCharacterRange, actualCharacterRange: nil)
    //when I refer to line numbers, I am referring to them by height, not in the document
    var currentLineNumber = 1
    let editorTextStorage = textStorage as EditorTextStorage
    func fragmentEnumerator(aRect:CGRect, aUsedRect:CGRect, textContainer:NSTextContainer!, glyphRange:NSRange, stop:UnsafeMutablePointer<ObjCBool>) -> Void {
      let fragmentCharacterRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
      let fragmentParagraphRange = editorTextStorage.string()!.paragraphRangeForRange(fragmentCharacterRange)
      let draggedParagraphRange = editorTextStorage.string()!.paragraphRangeForRange(draggedCharacterRange)
      if NSEqualRanges(draggedParagraphRange, fragmentParagraphRange) {
        //This means we've found the dragged line
        currentLineNumber++
        return
      }
      if fragmentCharacterRange.location == fragmentParagraphRange.location {
        //println("The length of the character range is \(fragmentCharacterRange.length), and the length of the paragraph range is \(fragmentParagraphRange.length)")
        var labelTextFrame = aRect
        labelTextFrame.size.height = font.lineHeight + lineSpacing
        let label = createLineLabel(labelTextFrame, fragmentCharacterRange: fragmentCharacterRange)
        label.frame.origin.x += gutterPadding
        label.frame.origin.y += lineSpacing + 3.5 //I have no idea why this isn't aligning properly, probably has to do with the sizeToFit()
        label.backgroundColor = UIColor.clearColor()
        dragOverlayLabels[currentLineNumber] = label
        originalDragOverlayLabelOffsets[currentLineNumber] = label.frame.origin.y
        currentLineNumber++
        addSubview(label)
      } else {
        //handle wrapped lines here
        println("Trying to create a view for a wrapped line")
      }
    }
    layoutManager.enumerateLineFragmentsForGlyphRange(visibleGlyphs, usingBlock: fragmentEnumerator)
  }
  
  func createLineLabel(lineFragmentRect:CGRect, fragmentCharacterRange:NSRange) -> UILabel {
    let label = UILabel(frame: lineFragmentRect)
    let editorTextStorage = textStorage as EditorTextStorage
    let fragmentParagraphRange = editorTextStorage.string()!.paragraphRangeForRange(fragmentCharacterRange)
    if fragmentCharacterRange.length == fragmentParagraphRange.length {
      label.attributedText = parentTextViewController.getAttributedStringForCharacterRange(fragmentParagraphRange)
    } else {
      var attributedStringBeforeLineBreak:NSMutableAttributedString!
      var attributedStringAfterLineBreak:NSMutableAttributedString!
      if fragmentCharacterRange.location == fragmentParagraphRange.location {
        //Dragging first line
        attributedStringBeforeLineBreak = NSMutableAttributedString(attributedString: parentTextViewController.getAttributedStringForCharacterRange(fragmentCharacterRange))
        attributedStringBeforeLineBreak.appendAttributedString(NSAttributedString(string: "\n"))
        attributedStringAfterLineBreak = NSMutableAttributedString(attributedString: parentTextViewController.getAttributedStringForCharacterRange(NSRange(location: NSMaxRange(fragmentCharacterRange), length: (fragmentParagraphRange.length - fragmentCharacterRange.length))))
        attributedStringBeforeLineBreak.appendAttributedString(attributedStringAfterLineBreak)
      } else {
        //Dragging second line, character range is smaller than paragraph range
        attributedStringBeforeLineBreak = NSMutableAttributedString(attributedString: parentTextViewController.getAttributedStringForCharacterRange(NSRange(location: fragmentParagraphRange.location, length: fragmentParagraphRange.length - fragmentCharacterRange.length)))
        attributedStringBeforeLineBreak.appendAttributedString(NSAttributedString(string: "\n"))
        attributedStringAfterLineBreak = NSMutableAttributedString(attributedString: parentTextViewController.getAttributedStringForCharacterRange(fragmentCharacterRange))
        attributedStringBeforeLineBreak.appendAttributedString(attributedStringAfterLineBreak)
      }
      
      label.lineBreakMode = NSLineBreakMode.ByWordWrapping
      label.numberOfLines = 0
      var paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = lineSpacing
      attributedStringBeforeLineBreak.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSRange(location: 0, length: attributedStringBeforeLineBreak.length))
      label.attributedText = attributedStringBeforeLineBreak
      label.frame.size.height += font.lineHeight + lineSpacing
    }
    //Handle any argument overlays here
    for (overlayLocation, overlay) in overlayLocationToViewMap {
      if overlayLocation >= fragmentCharacterRange.location && overlayLocation < fragmentCharacterRange.location + fragmentCharacterRange.length {
        //Render the view into an image
        UIGraphicsBeginImageContext(overlay.bounds.size)
        overlay.layer.renderInContext(UIGraphicsGetCurrentContext())
        let resultingImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageView = UIImageView(image: resultingImage)
        //Insert the image into the correct place
        //Get substring of everything before location
        let charactersBeforeOverlay = overlayLocation - fragmentCharacterRange.location
        let substringBeforeOverlay = label.attributedText.attributedSubstringFromRange(NSRange(location: 0, length: charactersBeforeOverlay))
        let widthToShiftOverBy = substringBeforeOverlay.size().width
        imageView.frame.origin.x = widthToShiftOverBy
        label.addSubview(imageView)
      }
    }
    label.sizeToFit()
    return label
  }
  
  func adjustLineViewsForDragLocation(loc:CGPoint) {
    //calculate which line the drag is currently on
    var lineNumber = lineNumberUnderPoint(loc)
    
    var maxLine = 1
    for key in dragOverlayLabels.keys {
      if key > maxLine {
        maxLine = key
      }
    }
    //Clamp lineNumber to available range
    lineNumber = max(lineNumber, 1)
    lineNumber = min(lineNumber, max(draggedLineNumber,maxLine))
    
    //If the drag has moved up, we need to move some lines down potentially
    if max(1,lineNumber) < draggedLineNumber {
      //Move the ones between the current drag location and dragged line
      for lineToMove in max(lineNumber,1)...(draggedLineNumber - 1) {
        if let labelToMove = dragOverlayLabels[lineToMove] {
          //check if offset is supposed to move
          if labelToMove.frame.origin.y == originalDragOverlayLabelOffsets[lineToMove]! {
            //shift down
            var oldFrame = labelToMove.frame
            oldFrame.origin.y += lineSpacing + font.lineHeight
            labelToMove.frame = oldFrame
            labelToMove.setNeedsLayout()
          }
        }
        
      }
      //Reset the ones above that
      if lineNumber != 1 && draggedLineNumber != 1 {
        for lineToReset in 1...max(1,lineNumber - 1) {
          if let labelToReset = dragOverlayLabels[lineToReset] {
            if labelToReset.frame.origin.y != originalDragOverlayLabelOffsets[lineToReset]! {
              var oldFrame = labelToReset.frame
              oldFrame.origin.y = originalDragOverlayLabelOffsets[lineToReset]!
              labelToReset.frame = oldFrame
              labelToReset.setNeedsLayout()
            }
          }
        }
      }
      
    } else if min(lineNumber,maxLine) > draggedLineNumber {
      //Move the lines between the dragged line and the current drag
      for lineToMove in (draggedLineNumber + 1)...min(lineNumber,maxLine) {
        if let labelToMove = dragOverlayLabels[lineToMove] {
          if labelToMove.frame.origin.y == originalDragOverlayLabelOffsets[lineToMove]! {
            var oldFrame = labelToMove.frame
            oldFrame.origin.y -= lineSpacing + font.lineHeight
            labelToMove.frame = oldFrame
            labelToMove.setNeedsLayout()
          }
        }
      }
      //Reset the ones below that
      if lineNumber != maxLine {
        for lineToReset in min(maxLine,lineNumber + 1)...maxLine {
          if let labelToReset = dragOverlayLabels[lineToReset] {
            if labelToReset.frame.origin.y != originalDragOverlayLabelOffsets[lineToReset]! {
              var oldFrame = labelToReset.frame
              oldFrame.origin.y = originalDragOverlayLabelOffsets[lineToReset]!
              labelToReset.frame = oldFrame
              labelToReset.setNeedsLayout()
            }
          }
        }
      }
    } else if lineNumber == draggedLineNumber {
      //println("Should maybe move lines back? Drag on dragged line number!")
      var linesToReset:[Int] = []
      if maxLine == 1 {
        return
      } else if draggedLineNumber == 1 {
        linesToReset.append(2)
      } else if draggedLineNumber > maxLine {
        linesToReset.append(maxLine)
      } else {
        linesToReset.append(draggedLineNumber - 1)
        linesToReset.append(draggedLineNumber + 1)
      }
      for lineToReset in linesToReset {
        if let labelToReset = dragOverlayLabels[lineToReset] {
          if labelToReset.frame.origin.y != originalDragOverlayLabelOffsets[lineToReset]! {
            var oldFrame = labelToReset.frame
            oldFrame.origin.y = originalDragOverlayLabelOffsets[lineToReset]!
            labelToReset.frame = oldFrame
            labelToReset.setNeedsLayout()
          }
        }
        
      }
    }
  }
  
  func clearLineOverlayLabels() {
    for (index, label) in dragOverlayLabels {
      label.removeFromSuperview()
    }
    dragOverlayLabels.removeAll(keepCapacity: true)
  }
  
}
