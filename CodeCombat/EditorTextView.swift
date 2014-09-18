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
  var currentHighlightingView:UIView? = nil
  var parameterViews:[ParameterView] = []
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
    let currentLine = Int(location.y / (font.lineHeight + lineSpacing))
    highlightLines(startingLineNumber: currentLine, numberOfLines: 1)
  }
  
  func handleItemPropertyDragEndedAtLocation(location:CGPoint, code:String) {
    currentHighlightingView?.removeFromSuperview()
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
      println("Inserting text on an empty line.")
    } else if draggedOntoLine == numberOfNewlinesBeforeGlyphIndex && characterAtGlyphIndex != 10 {
      println("Inserting text onto a line where there is text")
      stringToInsert = stringToInsert + "\n"
    } else if draggedOntoLine == numberOfNewlinesBeforeGlyphIndex && nearestGlyphIndex == storage.string()!.length - 1 {
      println("Dragged to last character!")
      stringToInsert = "\n" + stringToInsert
    } else if draggedOntoLine > numberOfNewlinesBeforeGlyphIndex { //adapt to deal with wrapped lines
      for var newlinesToInsertBeforeString = draggedOntoLine - numberOfNewlinesBeforeGlyphIndex; newlinesToInsertBeforeString >= 0; newlinesToInsertBeforeString-- {
        stringToInsert = "\n" + stringToInsert
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
        red: 1,
        green: 0,
        blue: 0,
        alpha: 0.2)
      addSubview(currentHighlightingView!)
    }
    currentHighlightingView?.frame = HighlightingRect
  }
}
