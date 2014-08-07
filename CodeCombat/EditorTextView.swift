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
    contentSize = CGSizeMake(bounds.size.width - lineNumberWidth, bounds.size.height)
    //contentInset = UIEdgeInsetsMake(0, 0, 0, lineNumberWidth * 5)
    shouldShowLineNumbers = true
    resizeLineNumberGutter()
  }
  
  private func resizeLineNumberGutter() {
    if !shouldShowLineNumbers {
      return
    }
    let TotalLines = 10 //Replace this with the actual total lines
    let TotalLinesString = NSString(string: "\(TotalLines)")
    let NumberOfCharacters = TotalLinesString.length
    //CHANGE THIS
    font = UIFont(name: "Courier", size: 20)
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
}
