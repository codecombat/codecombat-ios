//
//  EditorTextView.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class EditorTextView: UITextView {
  var shouldShowLineNumbers = false
  var textAttributes = Dictionary<NSObject, AnyObject>()
  var numberOfCharactersInLineNumberGutter = 0
  var lineNumberWidth = CGFloat(20.0)
  var currentDragView:UIView? = nil
  var currentHighlightingView:UIView? = nil
  
  override func drawRect(rect: CGRect) {
    
    if shouldShowLineNumbers {
      drawLineNumbers()
      
    }
    super.drawRect(rect)
  }
  
  private func drawLineNumbers() {
    let Storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    let LineNumberBackgroundColor = UIColor.grayColor()
    CGContextSetFillColorWithColor(Context, LineNumberBackgroundColor.CGColor)
    let LineNumberBackgroundRect = CGRectMake(Bounds.origin.x, Bounds.origin.y, lineNumberWidth, Bounds.size.height)
    CGContextFillRect(Context, LineNumberBackgroundRect)
    
    let textRange = layoutManager.glyphRangeForBoundingRect(Bounds, inTextContainer: textContainer)
    let GlyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange, actualCharacterRange: nil)
    var lineNumber = 0
    let FirstLine = 0 //compute this somehow
    var visibleLines = 0
    layoutManager.enumerateLineFragmentsForGlyphRange(GlyphsToShow,
      usingBlock: { [weak self] aRect, aUsedRect, textContainer, glyphRange, stop in
        let CharacterRange = self!.layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
        let ParagraphRange = Storage.string()!.paragraphRangeForRange(CharacterRange)
        //To avoid drawing numbers on wrapped lines
        if NSEqualRanges(CharacterRange, ParagraphRange) {
          visibleLines++
          lineNumber++
          let LineNumberString = NSString(string: "\(lineNumber)")
          let Size = LineNumberString.sizeWithAttributes(self!.textAttributes)
          let Point = CGPointMake(self!.lineNumberWidth - 4 - Size.width, aRect.origin.y + 8)
          LineNumberString.drawAtPoint(Point, withAttributes: self!.textAttributes)
        }
    })
  }
  
  func showLineNumbers() {
    if shouldShowLineNumbers {
      return
    }
    font = UIFont(name: "Courier", size: 20)
    contentSize = CGSizeMake(bounds.size.width - lineNumberWidth, bounds.size.height)
    //contentInset = UIEdgeInsetsMake(0, 0, 0, lineNumberWidth * 5)
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
      let Rect = CGRectMake(ContainerRect.origin.x, ContainerRect.origin.y, Size.width + GutterPadding, CGFloat.max)
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
    textStorage.insertAttributedString(NSAttributedString(string: code), atIndex: 0)
    
  }
  
  func getLineHeightAtPoint(location:CGPoint) -> Int {
    let LineHeight = font.lineHeight
    let EditorHeight = frame.height
    return Int(location.y / LineHeight)
  }
  func getLineNumberRect(lineNumber:Int) -> CGRect{
    let LineHeight = CGFloat(font.lineHeight)
    let LineNumberRect = CGRectMake(0, LineHeight * CGFloat(lineNumber), frame.width, LineHeight)
    return LineNumberRect
  }
  
  func highlightLines(#startingLineNumber:Int, numberOfLines:Int) {
    let FirstLineNumberRect = getLineNumberRect(startingLineNumber)
    let HighlightingRect = CGRectMake(FirstLineNumberRect.origin.x, FirstLineNumberRect.origin.y , FirstLineNumberRect.width, FirstLineNumberRect.height * CGFloat(numberOfLines))
    if currentHighlightingView == nil {
      currentHighlightingView = UIView(frame: HighlightingRect)
      currentHighlightingView?.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.2)
      addSubview(currentHighlightingView!)
    }
    currentHighlightingView?.frame = HighlightingRect
  }
}
