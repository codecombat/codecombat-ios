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

class EditorTextView: UITextView {
  var shouldShowLineNumbers = false
  var textAttributes = Dictionary<NSObject, AnyObject>()
  var numberOfCharactersInLineNumberGutter = 0
  var lineNumberWidth = CGFloat(20.0)
  var currentDragView:UIView? = nil
  var currentHighlightingView:UIView? = nil
  var parameterViews:[ParameterView] = []
  
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleDrawParameterRequest:"), name: "drawParameterBox", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("eraseParameterViews:"), name: "eraseParameterBoxes", object: nil)
  }

  required init(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
  }
  
  override func drawRect(rect: CGRect) {
    if shouldShowLineNumbers {
      drawLineNumberBackground()
      drawLineNumbers()
    }
    //drawClickableBoxesOnHello()
    super.drawRect(rect)
  }
  
  func eraseParameterViews(notification:NSNotification) {
    println("Erasing boxes...")
    for v in parameterViews {
      v.removeFromSuperview()
    }
    parameterViews = []
  }
  
  func handleDrawParameterRequest(notification:NSNotification) {
    let info = notification.userInfo!
    let functionName:NSString? = info["functionName"] as? NSString
    let range:NSRange = (info["rangeValue"] as? NSValue)!.rangeValue
    println("Should be drawing a box for func \(functionName!)")
    let start = positionFromPosition(beginningOfDocument, offset: range.location)
    let end = positionFromPosition(start!, offset: range.length)
    let textRange = textRangeFromPosition(start, toPosition: end)
    let resultRect =  firstRectForRange(textRange)
    let paramView = ParameterView(frame: resultRect)
    paramView.range = range
    paramView.functionName = functionName!
    paramView.backgroundColor = UIColor(hue: CGFloat(drand48()), saturation: 1.0, brightness: 1.0, alpha: 0.1)
    addSubview(paramView)
    parameterViews.append(paramView)
    
  }
  
  private func drawClickableBoxesOnHello() {
    let helloExpression = NSRegularExpression(
    pattern: "hello",
    options: nil,
    error: nil)
    let stringToDrawUpon = textStorage.string
    let range = NSMakeRange(0, stringToDrawUpon.utf16Count)
    let matches = helloExpression.matchesInString(stringToDrawUpon,
      options: nil,
      range: range)
    for regexMatch in matches {
      let match = regexMatch as NSTextCheckingResult
      let start = positionFromPosition(beginningOfDocument, offset: match.range.location)
      let end =  positionFromPosition(start!, offset: match.range.length)
      let textRange = textRangeFromPosition(start, toPosition: end)
      
      let resultRect = firstRectForRange(textRange)
      let highlightView = UIView(frame: resultRect)
      highlightView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
      addSubview(highlightView)
    }
  }
  
  private func drawLineNumbers() {
    let Storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    
    let textRange = layoutManager.glyphRangeForBoundingRect(Bounds,
      inTextContainer: textContainer)
    let GlyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange,
      actualCharacterRange: nil)
    var lineNumber = 0
    let FirstLine = 0 //compute this somehow
    var visibleLines = 0
    func lineFragmentClosure(aRect:CGRect, aUsedRect:CGRect,
      textContainer:NSTextContainer!, glyphRange:NSRange,
      stop:UnsafeMutablePointer<ObjCBool>) -> Void {
        let CharacterRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
        let ParagraphRange = Storage.string()!.paragraphRangeForRange(CharacterRange)
        //To avoid drawing numbers on wrapped lines
        if NSEqualRanges(CharacterRange, ParagraphRange) {
          visibleLines++
          lineNumber++
          let LineNumberString = NSString(string: "\(lineNumber)")
          let Size = LineNumberString.sizeWithAttributes(textAttributes)
          let Point = CGPointMake(lineNumberWidth - 4 - Size.width, aRect.origin.y + 8)
          LineNumberString.drawAtPoint(Point, withAttributes: textAttributes)
        }
    }
    layoutManager.enumerateLineFragmentsForGlyphRange(GlyphsToShow,
      usingBlock: lineFragmentClosure)
  }
  
  private func drawLineNumberBackground() {
    let context = UIGraphicsGetCurrentContext()
    let LineNumberBackgroundColor = UIColor(
      red: CGFloat(234.0/256.0),
      green: CGFloat(219.0/256.0),
      blue: CGFloat(169.0/256.0),
      alpha: 1)
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
      let GutterPadding = CGFloat(5.0)
      let Rect = CGRect(
        x: ContainerRect.origin.x,
        y: ContainerRect.origin.y,
        width: Size.width + GutterPadding,
        height: CGFloat.max)
      lineNumberWidth = Rect.size.width
      textContainer.exclusionPaths = [UIBezierPath(rect: Rect)]
      numberOfCharactersInLineNumberGutter = NumberOfCharacters
    }
    setNeedsDisplay()
  }
  
  func handleItemPropertyDragChangedAtLocation(location:CGPoint, code:String) {
    let currentLine = getLineHeightAtPoint(location)
    highlightLines(startingLineNumber: currentLine, numberOfLines: 1)
  }
  
  func handleItemPropertyDragEndedAtLocation(location:CGPoint, code:String) {
    currentHighlightingView?.removeFromSuperview()
    currentHighlightingView = nil
    let dragPoint = CGPoint(x: 0, y: location.y)
    let GlyphIndex = layoutManager.glyphIndexForPoint(dragPoint,
      inTextContainer: textContainer)
    textStorage.beginEditing()
    textStorage.insertAttributedString(NSAttributedString(string: code),
      atIndex: GlyphIndex)
    textStorage.endEditing()
    setNeedsDisplay()
    
  }
  
  func getLineHeightAtPoint(location:CGPoint) -> Int {
    let LineHeight = font.lineHeight
    let EditorHeight = frame.height
    return Int(location.y / LineHeight)
  }
  func getLineNumberRect(lineNumber:Int) -> CGRect{
    let LineHeight = CGFloat(font.lineHeight)
    let LineNumberRect = CGRect(
      x: 0,
      y: LineHeight * CGFloat(lineNumber),
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
        red: 1,
        green: 0,
        blue: 0,
        alpha: 0.2)
      addSubview(currentHighlightingView!)
    }
    currentHighlightingView?.frame = HighlightingRect
  }
}
