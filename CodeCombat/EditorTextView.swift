//
//  EditorTextView.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class ParameterView:UIView {
  var range:NSRange!
  var functionName:String = ""
  //do something with unique identifier here
}

class GutterProblemLineAnnotationButton: UIButton {
  var problemDescription:String = ""
}

class EditorTextView: UITextView {
  var shouldShowLineNumbers = false
  var numberOfCharactersInLineNumberGutter = 0
  var lineNumberWidth = CGFloat(20.0)
  var currentDragView:UIView? = nil
  var currentDragHintView:ParticleView?
  var currentHighlightingView:UIView? = nil
  var currentLineHighlightingView:UIView? = nil
  var errorMessageView:UILabel? = nil
  var currentProblemGutterLineAnnotations:[Int:GutterProblemLineAnnotationButton] = [:]
  var currentProblemLineHighlights:[Int:UIView] = [:]
  var parameterViews:[ParameterView] = []
  let gutterPadding = CGFloat(5.0)
  let lineSpacing:CGFloat = 5
  var accessoryView:UIView?
  
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
  
  func eraseParameterViews() {
    println("Erasing boxes...")
    for v in parameterViews {
      v.removeFromSuperview()
    }
    parameterViews = []
  }
  
  
  func drawParameterOverlay(range:NSRange) {
    let start = positionFromPosition(beginningOfDocument, offset: range.location)
    let end = positionFromPosition(start!, offset: range.length)
    let textRange = textRangeFromPosition(start, toPosition: end)
    let resultRect =  firstRectForRange(textRange)
    let paramView = ParameterView(frame: resultRect)
    paramView.range = range
    paramView.backgroundColor = UIColor(hue: CGFloat(drand48()), saturation: 1.0, brightness: 1.0, alpha: 0.1)
    addSubview(paramView)
    parameterViews.append(paramView)
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
  
  func handleItemPropertyDragBegan() {
    let glyphRange = layoutManager.glyphRangeForTextContainer(textContainer)
    var lastLineFragmentRect = layoutManager.lineFragmentRectForGlyphAtIndex(NSMaxRange(glyphRange) - 1, effectiveRange: nil)
    let bufferHeight = 100
    let lineHeight = font.lineHeight + lineSpacing
    lastLineFragmentRect.origin.y += lineHeight + lineSpacing - CGFloat(bufferHeight/2)
    lastLineFragmentRect.size.height = lineHeight + CGFloat(bufferHeight)
    currentDragHintView = ParticleView(frame: lastLineFragmentRect)
    addSubview(currentDragHintView!)
  }
  
  func handleItemPropertyDragChangedAtLocation(location:CGPoint, code:String) {
    let currentLine = Int(location.y / (font.lineHeight + lineSpacing))
    highlightLines(startingLineNumber: currentLine, numberOfLines: 1)
  }
  
  func handleItemPropertyDragEndedAtLocation(location:CGPoint, code:String) {
    currentHighlightingView?.removeFromSuperview()
    currentDragHintView?.removeFromSuperview()
    currentHighlightingView = nil
    let storage = textStorage as EditorTextStorage
    
    let dragPoint = CGPoint(x: 0, y: location.y)
    let nearestGlyphIndex = layoutManager.glyphIndexForPoint(dragPoint,
      inTextContainer: textContainer) //nearest glyph index
    //This may cause some really really weird bugs if glyphs and character indices don't correspond.
    let nearestCharacterIndex = layoutManager.characterIndexForGlyphAtIndex(nearestGlyphIndex)
    
    let draggedOntoLine = Int(location.y / (font.lineHeight + lineSpacing)) + 1
    var numberOfNewlinesBeforeGlyphIndex = 1
    for var index = 0; index < nearestGlyphIndex; numberOfNewlinesBeforeGlyphIndex++ {
      index = NSMaxRange(storage.string()!.lineRangeForRange(NSRange(location: index, length: 0)))
    }
    
    var totalLinesInDoc = 1
    for var index = 0; index < storage.string()!.length; totalLinesInDoc++ {
      index = NSMaxRange(storage.string()!.lineRangeForRange(NSRange(location: index, length: 0)))
    }
    
    let characterAtGlyphIndex = storage.string()!.characterAtIndex(nearestGlyphIndex)
    let characterBeforeGlyphIndex = storage.string()!.characterAtIndex(nearestGlyphIndex - 1)
    var stringToInsert = code
    var newlinesToInsert = draggedOntoLine - numberOfNewlinesBeforeGlyphIndex
    //Check if dragging onto an empty line in between two other lines of code.
    if characterAtGlyphIndex == 10 && characterBeforeGlyphIndex == 10 {
    } else if draggedOntoLine == numberOfNewlinesBeforeGlyphIndex && characterAtGlyphIndex != 10 {
      stringToInsert = stringToInsert + "\n"
    } else if draggedOntoLine == numberOfNewlinesBeforeGlyphIndex && nearestGlyphIndex == storage.string()!.length - 1 {
      stringToInsert = "\n" + stringToInsert
    } else if draggedOntoLine > numberOfNewlinesBeforeGlyphIndex { //adapt to deal with wrapped lines
      for var newlinesToInsertBeforeString = draggedOntoLine - numberOfNewlinesBeforeGlyphIndex; newlinesToInsertBeforeString > 0; newlinesToInsertBeforeString-- {
        stringToInsert = "\n" + stringToInsert  // TODO: figure out why something was prepending newlines in Gems in the Deep; > 0 used to be >= 0, dunno if that works.
      }
    }
    //Adjust code to match indentation level and other languages
    stringToInsert = fixIndentationLevelForPython(nearestCharacterIndex, lineNumber: draggedOntoLine, rawString: stringToInsert)
    
    //Check if code contains a placeholder
    if codeContainsPlaceholder(stringToInsert) {
      let placeholderReplacement = getPlaceholderWidthString(stringToInsert)
      stringToInsert = replacePlaceholderInString(stringToInsert, replacement: placeholderReplacement)
    }
    
    storage.replaceCharactersInRange(NSRange(location: nearestGlyphIndex, length: 0), withString: stringToInsert)
    setNeedsDisplay()
  }
  
  private func fixIndentationLevelForPython(firstCharacterIndex:Int, lineNumber:Int, rawString:String) -> String {
    let numberOfSpacesForIndentation = 4
    var indentationLevel = indentationLevelOfLine(lineNumber - 1)
    //58 is ASCII for :
    if firstNonWhitespaceCharacterBeforeCharacterIndex(firstCharacterIndex) == 58 {
      indentationLevel++
    }
    return String(count: numberOfSpacesForIndentation * indentationLevel, repeatedValue: " " as Character) + rawString
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
