//
//  EditorTextView.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class EditorTextView: UITextView {
  var showLineNumbers = true
  var textAttributes = Dictionary<NSObject, AnyObject>()

  override func drawRect(rect: CGRect) {
    if showLineNumbers {
      drawLineNumbers()
      
    }
    super.drawRect(rect)
  }
  
  private func drawLineNumbers() {
    let Storage = textStorage as EditorTextStorage
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    let LineNumberBackgroundColor = UIColor.grayColor()
    let LineNumberWidth = CGFloat(20.0)
    CGContextSetFillColorWithColor(Context, LineNumberBackgroundColor.CGColor)
    let LineNumberBackgroundRect = CGRectMake(Bounds.origin.x, Bounds.origin.y, LineNumberWidth, Bounds.size.height)
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
          let Point = CGPointMake(LineNumberWidth - Size.width, aRect.origin.y + 8)
          LineNumberString.drawAtPoint(Point, withAttributes: self!.textAttributes)
        }
    })
  }
  
    
}
