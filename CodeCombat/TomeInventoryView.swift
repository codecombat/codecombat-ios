//
//  TomeInventory.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import QuartzCore

class TomeInventoryView: UIScrollView, UIGestureRecognizerDelegate {
  
  var items: [TomeInventoryItem] = []
  var itemHeight: CGFloat = CGFloat(0.0)
  var currentDragRecognizer:UIPanGestureRecognizer? = nil
  var currentDraggedItemProperty:TomeInventoryItemProperty? = nil
  var dragAndDropRecognizer:UIPanGestureRecognizer? = nil

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
    setupGestureRecognizer()
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
    let Margin = CGFloat(5.0)
    let itemFrame = CGRect(x: Margin, y: itemHeight + Margin, width: self.frame.width - 2 * Margin, height: self.frame.height - itemHeight - 2 * Margin)
    let itemView = TomeInventoryItemView(item: item, frame: itemFrame)
    if itemView.showsProperties {
      addSubview(itemView)
      itemHeight += itemView.frame.height + 2 * Margin
    }
    items.append(item)
  }
  
  func setupGestureRecognizer() {
    dragAndDropRecognizer = UIPanGestureRecognizer(target: self, action: "handleDrag:")
    addGestureRecognizer(dragAndDropRecognizer!)
    panGestureRecognizer.requireGestureRecognizerToFail(dragAndDropRecognizer!)
  }
  
  func handleDrag(recognizer:UIPanGestureRecognizer) {
    var itemView:TomeInventoryItemView? = nil
    switch recognizer.state {
    case .Began:
      if currentDragRecognizer != nil {
        return
      }
      let Item = tomeInventoryItemPropertyAtLocationWithRecognizer(recognizer)
      if Item == nil {
        recognizer.enabled = false
        recognizer.enabled = true
      } else {
        currentDragRecognizer = recognizer
        currentDraggedItemProperty = Item
      }
      
      break
    case .Ended:
      if recognizer == currentDragRecognizer {
        currentDragRecognizer = nil
        println(currentDraggedItemProperty!.propertyData["name"])
      }
      break
    case .Changed:
      
      break
    default:
      break
    }
  }
  
  func tomeInventoryItemPropertyAtLocationWithRecognizer(recognizer:UIPanGestureRecognizer) -> TomeInventoryItemProperty? {
    for subview in subviews {
      if !subview.isKindOfClass(TomeInventoryItemView) {
        continue
      }
      let CandidateView = subview as TomeInventoryItemView
      if CandidateView.frame.contains(recognizer.locationInView(self)) {
        return CandidateView.tomeInventoryItemPropertyAtLocation(recognizer.locationInView(CandidateView))
      }
    }
    return nil
  }
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
    if gestureRecognizer == panGestureRecognizer && otherGestureRecognizer == dragAndDropRecognizer ||
      otherGestureRecognizer == panGestureRecognizer && gestureRecognizer == dragAndDropRecognizer {
        return true
    }
    return false
  }
  
}
