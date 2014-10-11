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
  var numberOfCharactersInLineNumberGutter = 0
  var lineNumberWidth = CGFloat(20.0)
  var currentDragView:UIView? = nil
  var currentDragHintView:ParticleView?
  var currentHighlightingView:UIView? = nil
  var currentLineHighlightingView:UIView? = nil
  var parameterViews:[ParameterView] = []
  let gutterPadding = CGFloat(5.0)
  let lineSpacing:CGFloat = 5
  override func drawRect(rect: CGRect) {
    if shouldShowLineNumbers {
      drawLineNumberBackground()
      drawLineNumbers(rect)
    }
    super.drawRect(rect)
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
    if currentLineHighlightingView != nil {
      currentLineHighlightingView!.removeFromSuperview()
      currentLineHighlightingView = nil
    }
    var lineFragmentFrame = lineFragmentRectForLineNumber(lineNumber)
    lineFragmentFrame.origin.y += lineSpacing
    currentLineHighlightingView = UIView(frame:lineFragmentFrame )
    currentLineHighlightingView!.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.3)
    addSubview(currentLineHighlightingView!)
  }
  
  private func lineFragmentRectForLineNumber(targetLineNumber:Int) -> CGRect {
    //figure out how to optimize this through caching
    let storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    
    let textRange = layoutManager.glyphRangeForTextContainer(textContainer)
    let glyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange,
      actualCharacterRange: nil)
    //find number of lines before textRange.location
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
    //find number of lines before textRange.location
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
    //create a coloured box on the line past the last line here
    //identify location of last glyph index
    let glyphRange = layoutManager.glyphRangeForTextContainer(textContainer)
    var lastLineFragmentRect = layoutManager.lineFragmentRectForGlyphAtIndex(NSMaxRange(glyphRange) - 1, effectiveRange: nil)
    //now add one line height
    let bufferHeight = 100
    let lineHeight = font.lineHeight + lineSpacing
    lastLineFragmentRect.origin.y += lineHeight + lineSpacing - CGFloat(bufferHeight/2)
    lastLineFragmentRect.size.height = lineHeight + CGFloat(bufferHeight)
    //create a view
    currentDragHintView = ParticleView(frame: lastLineFragmentRect)
    //currentDragHintView = UIView(frame: lastLineFragmentRect)
    //currentDragHintView!.backgroundColor = UIColor.greenColor()
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
    textStorage.beginEditing()
    storage.replaceCharactersInRange(NSRange(location: nearestGlyphIndex, length: 0), withString: stringToInsert)
    textStorage.endEditing()
    setNeedsDisplay()
    
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
