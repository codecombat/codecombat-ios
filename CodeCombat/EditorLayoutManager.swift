//
//  EditorLayoutManager.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/30/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class EditorLayoutManager: NSLayoutManager {
  
  override func drawUnderlineForGlyphRange(glyphRange: NSRange,
    underlineType underlineVal: NSUnderlineStyle,
    baselineOffset: CGFloat,
    lineFragmentRect lineRect: CGRect,
    lineFragmentGlyphRange lineGlyphRange: NSRange,
    containerOrigin: CGPoint) {
    let firstPosition = locationForGlyphAtIndex(glyphRange.location).x
    
    var lastPosition:CGFloat
    if (NSMaxRange(glyphRange) < NSMaxRange(lineGlyphRange)) {
      lastPosition = locationForGlyphAtIndex(NSMaxRange(glyphRange)).x
    } else {
      lastPosition = lineFragmentRectForGlyphAtIndex(NSMaxRange(glyphRange) - 1,
        effectiveRange: nil).size.width
    }
    let newRect = CGRectMake(lineRect.origin.x + firstPosition + containerOrigin.x,
      lineRect.origin.y + containerOrigin.y, lastPosition - firstPosition, lineRect.size.height)
    let BoxRect = CGRectInset(CGRectIntegral(newRect), 0.5, 0.5)
    UIColor.greenColor().set()
    UIBezierPath(rect: BoxRect).stroke()
  }

}
