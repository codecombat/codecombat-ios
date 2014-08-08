//
//  TomeInventory.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import QuartzCore

class TomeInventoryView: UIScrollView {
  
  var items: [TomeInventoryItem] = []

  func baseInit() {
    bounces = false
    backgroundColor = UIColor.blueColor()
    let width = frame.width
    let height = 2 * frame.height
    let gradient = CAGradientLayer()
    contentSize = CGSizeMake(width, height)
    gradient.frame = CGRectMake(0, 0, width, height)
    let gradientColors: Array <AnyObject> = [UIColor.blackColor().CGColor, UIColor.orangeColor().CGColor]
    gradient.colors = gradientColors
    layer.insertSublayer(gradient, atIndex: 0)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    baseInit()
  }
  
  required init(coder aDecoder: NSCoder!) {
    super.init(coder: aDecoder)
    baseInit()
  }
  
  func addItem(item: TomeInventoryItem) {
    let LineHeight = 30
    let y = CGFloat(LineHeight * items.count)
    let itemFrame = CGRect(x: 0, y: y, width: self.frame.width, height: CGFloat(LineHeight))
    let itemView = TomeInventoryItemView(item: item, frame: itemFrame)
    items.append(item)
    addSubview(itemView)
  }
}
