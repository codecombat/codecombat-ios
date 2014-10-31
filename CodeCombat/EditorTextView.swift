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
  var currentHighlightingView:UIView? = nil
  var currentLineHighlightingView:UIView? = nil
  var errorMessageView:UILabel? = nil
  var currentProblemGutterLineAnnotations:[Int:GutterProblemLineAnnotationButton] = [:]
  var currentProblemLineHighlights:[Int:UIView] = [:]
  var overlayLocationToViewMap:[Int:ArgumentOverlayView] = [:]
  let gutterPadding = CGFloat(5.0)
  let lineSpacing:CGFloat = 5
  var accessoryView:UIView?
  var textViewCoverView:UIView?
  
  var keyboardModeEnabled:Bool {
    return editable && selectable
  }
  
  func layoutManager(layoutManager: NSLayoutManager, lineSpacingAfterGlyphAtIndex glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
    return lineSpacing
  }
  
  func layoutManager(layoutManager: NSLayoutManager, didCompleteLayoutForTextContainer textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
    processOverlayRequests(parentTextViewController.getArgumentOverlays())
  }
  
  func createDeletionOverlayView() {
    var deleteOverlayFrame = frame
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
  
  //Will create a blank view covering entire text view
  func createTextViewCoverView() {
    var coverTextFrame = bounds
    coverTextFrame.origin.x += lineNumberWidth + gutterPadding
    textViewCoverView = UIView(frame: coverTextFrame)
    textViewCoverView!.backgroundColor = backgroundColor
    addSubview(textViewCoverView!)
  }
  
  func removeTextViewCoverView() {
    textViewCoverView?.removeFromSuperview()
    textViewCoverView = nil
  }
  
  func toggleKeyboardMode() {
    editable = !editable
    selectable = !selectable
    if isFirstResponder() {
      resignFirstResponder()
    } else {
      becomeFirstResponder()
    }
  }
  
  func removeAllOverlaysNotRequested(requestedOverlayFunctionNamesAndRanges:[(String, NSRange)]) {
    let overlayRequestLocations = requestedOverlayFunctionNamesAndRanges.map({$0.1.location})
    for (overlayLocation, overlay) in overlayLocationToViewMap {
      if !contains(overlayRequestLocations, overlayLocation) {
        overlay.removeFromSuperview()
        overlayLocationToViewMap.removeValueForKey(overlayLocation)
      }
    }
  }
  
  func processOverlayRequests(requestedOverlayFunctionNamesAndRanges:[(String, NSRange)]) {
    removeAllOverlaysNotRequested(requestedOverlayFunctionNamesAndRanges)
    for (functionName,overlayRange) in requestedOverlayFunctionNamesAndRanges {
      //if view already exists and is requested, don't redraw
      if overlayLocationToViewMap.indexForKey(overlayRange.location) != nil {
        continue
      }
      let range = overlayRange
      //to render views http://stackoverflow.com/questions/788662/rendering-uiview-with-its-children
      let defaultRect = CGRect()
      let newView = ArgumentOverlayView(
        frame: defaultRect,
        textViewController: parentTextViewController,
        characterRange: overlayRange,
        functionName: "blah")
      
      overlayLocationToViewMap[range.location] = newView
      addSubview(newView)
    }
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
  
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    autocorrectionType = UITextAutocorrectionType.No
    autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    selectable = false
    editable = false
    //Not sure if this will get reset, if it does it will cause bugs
    font = UIFont(name: "Courier", size: 22)
    showLineNumbers()
    backgroundColor = UIColor(
      red: CGFloat(230.0 / 256.0),
      green: CGFloat(212.0 / 256.0),
      blue: CGFloat(145.0 / 256.0),
      alpha: 1)
    layoutManager.delegate = self
    
  }

  required init(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
  }
  
  override func drawRect(rect: CGRect) {
    if shouldShowLineNumbers {
      drawLineNumberBackground()
      drawLineNumbers(rect)
    }
    super.drawRect(rect)
  }
  
  func expandSelectionLeft() {
    if selectedRange.location > 0 {
      selectedRange.location--
      selectedRange.length++
    }
  }
  
  func expandSelectionRight() {
    if selectedRange.location < textStorage.length {
      selectedRange.length++
    }
  }
  
  func moveCursorLeft() {
    if selectedRange.location > 0 {
      selectedRange.location--
    }
  }
  
  func moveCursorRight() {
    if selectedRange.location < textStorage.length {
      selectedRange.location++
      if selectedRange.length > 0 {
        selectedRange.length--
      }
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
  
  func highlightLineUnderLocation(location:CGPoint) {
    let currentLine = Int(location.y / (font.lineHeight + lineSpacing))
    highlightLines(startingLineNumber: currentLine, numberOfLines: 1)
  }
  
  func highlightLineNumber(lineNumber:Int) {
    removeCurrentLineNumberHighlight()
    var lineFragmentFrame = lineFragmentRectForLineNumber(lineNumber)
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
      var frame = lineFragmentRectForLineNumber(lineNumber)
      frame.origin.y += lineSpacing
      let highlightView = UIView(frame: frame)
      highlightView.backgroundColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.3)
      currentProblemLineHighlights[lineNumber] = highlightView
      addSubview(highlightView)
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
      var frame = lineFragmentRectForLineNumber(lineNumber)
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
      currentProblemGutterLineAnnotations[lineNumber] = gutterAnnotation
      addSubview(gutterAnnotation)
    }
  }
  
  func displayProblemErrorMessageFromView(sender:GutterProblemLineAnnotationButton) {
    if errorMessageView == nil {
      displayProblemErrorMessage(sender.problemDescription)
    } else {
      //hide the display problem error message
      UIView.animateWithDuration(0.5, animations: { self.errorMessageView!.alpha = 0 }, completion: { (Bool) -> Void in
        self.clearErrorMessageView()
      })
    }
    
  }
  
  func displayProblemErrorMessage(message:String) {
    if errorMessageView != nil {
      clearErrorMessageView()
    }
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
    errorMessageView?.text = message
    errorMessageView?.backgroundColor = UIColor(patternImage: backgroundImage)
    errorMessageView?.alpha = 0
    errorMessageView?.textColor = UIColor.whiteColor()
    mainScreenView.addSubview(errorMessageView!)
    UIView.animateWithDuration(0.5, animations: {
      self.errorMessageView!.alpha = 1
    })
    
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
  
  //Draws a solid brown background behind the lines
  private func drawLineNumberBackground() {
    let context = UIGraphicsGetCurrentContext()
    let LineNumberBackgroundColor = ColorManager.sharedInstance.inventoryBackground
    CGContextSetFillColorWithColor(context, LineNumberBackgroundColor.CGColor)
    let LineNumberBackgroundRect = CGRect(
      x: bounds.origin.x,
      y: bounds.origin.y,
      width: lineNumberWidth,
      height: bounds.size.height)
    CGContextFillRect(context, LineNumberBackgroundRect)
  }
  
  func showLineNumbers() {
    if shouldShowLineNumbers {
      return
    }
    font = UIFont(name: "Courier", size: 20)
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
      textContainer.exclusionPaths = [UIBezierPath(rect: Rect)]
      numberOfCharactersInLineNumberGutter = NumberOfCharacters
    }
    setNeedsDisplay()
  }

  
  func fixIndentationLevelForPython(firstCharacterIndex:Int, lineNumber:Int, rawString:String) -> String {
    let numberOfSpacesForIndentation = 4
    var indentationLevel = indentationLevelOfLine(lineNumber - 1)
    //58 is ASCII for :
    if firstNonWhitespaceCharacterBeforeCharacterIndex(firstCharacterIndex) == 58 {
      indentationLevel++
    }
    
    let stringToReturn = String(count: numberOfSpacesForIndentation * indentationLevel, repeatedValue: " " as Character) + rawString
    println("Returning string \(stringToReturn)")
    return stringToReturn
  }
  
  private func indentationLevelOfLine(lineNumber:Int) -> Int {
    let storage = textStorage as EditorTextStorage
    if lineNumber <= 0 {
      return 0
    } else {
      let lines = storage.string()!.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
      let line = lines[lineNumber - 1] as NSString
      var spacesCount = 0
      for var charIndex = 0; charIndex < line.length; charIndex++ {
        let character = line.characterAtIndex(charIndex)
        if NSCharacterSet.whitespaceCharacterSet().characterIsMember(character) {
          spacesCount++
        } else {
          break
        }
      }
      let indentationLevel = spacesCount / 4
      return indentationLevel
    }
  }
  
  private func firstNonWhitespaceCharacterBeforeCharacterIndex(index:Int) -> unichar {
    let storage = textStorage as EditorTextStorage
    
    var firstNonWhitespaceCharacter = unichar(10)
    for var charIndex = index; charIndex > 0; charIndex-- {
      let character = storage.string()!.characterAtIndex(charIndex)
      if !NSCharacterSet.whitespaceAndNewlineCharacterSet().characterIsMember(character) {
        firstNonWhitespaceCharacter = character
        break
      }
    }
    return firstNonWhitespaceCharacter
  }
  
  func codeContainsPlaceholder(code:String) -> Bool {
    var error:NSErrorPointer = nil
    
    let regex = NSRegularExpression(pattern: "\\$\\{.*\\}", options: nil, error: error)
    let matches = regex!.matchesInString(code, options: nil, range: NSRange(location: 0, length: countElements(code)))
    return matches.count > 0
  }
  
  func getPlaceholderWidthString(code:String) -> String {
    return "${1:d}"
  }
  
  func replacePlaceholderInString(code:String, replacement:String) -> String {
    var error:NSErrorPointer = nil
    let regex = NSRegularExpression(pattern: "\\$\\{.*\\}", options: nil, error: error)
    let matches = regex!.matchesInString(code, options: nil, range: NSRange(location: 0, length: countElements(code)))
    let firstMatch = matches[0] as NSTextCheckingResult
    let newString = NSString(string: code).stringByReplacingCharactersInRange(firstMatch.range, withString: replacement)
    return newString
  }
  
  func getLineNumberRect(lineNumber:Int) -> CGRect{
    let LineHeight = font.lineHeight + lineSpacing
    let LineNumberRect = CGRect(
      x: 0,
      y: LineHeight * CGFloat(lineNumber) + lineSpacing,
      width: frame.width,
      height: LineHeight)
    return LineNumberRect
  }
  
  func highlightLines(#startingLineNumber:Int, numberOfLines:Int) {
    let FirstLineNumberRect = getLineNumberRect(startingLineNumber)
    let HighlightingRect = CGRect(
      x: FirstLineNumberRect.origin.x,
      y: FirstLineNumberRect.origin.y,
      width: FirstLineNumberRect.width,
      height: FirstLineNumberRect.height * CGFloat(numberOfLines))
    if currentHighlightingView == nil {
      currentHighlightingView = UIView(frame: HighlightingRect)
      currentHighlightingView?.backgroundColor = UIColor(
        red: 0,
        green: 0,
        blue: 0,
        alpha: 0.2)
      addSubview(currentHighlightingView!)
    }
    currentHighlightingView?.frame = HighlightingRect
  }
  
}
