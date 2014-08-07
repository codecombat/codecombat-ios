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

  override func drawRect(rect: CGRect) {
    if showLineNumbers {
      drawLineNumbers()
      
    }
    super.drawRect(rect)
  }
  
  func drawLineNumbers() {
    let Context = UIGraphicsGetCurrentContext()
    let Bounds = bounds
    let LineNumberBackgroundColor = UIColor.grayColor()
    let LineNumberWidth = CGFloat(20.0)
    CGContextSetFillColorWithColor(Context, LineNumberBackgroundColor.CGColor)
    let LineNumberBackgroundRect = CGRectMake(Bounds.origin.x, Bounds.origin.y, LineNumberWidth, Bounds.size.height)
    CGContextFillRect(Context, LineNumberBackgroundRect)
    
    let textRange = layoutManager.glyphRangeForBoundingRect(Bounds, inTextContainer: textContainer)
    let GlyphsToShow = layoutManager.glyphRangeForCharacterRange(textRange, actualCharacterRange: nil)    
  }
}
