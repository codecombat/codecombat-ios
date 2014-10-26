//
//  TomeInventoryItemView.swift
//  CodeCombat
//
//  Created by Nick Winter on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

class TomeInventoryItemView: UIView {
  var item: TomeInventoryItem!
  var showsProperties = false
  var imageView: UIImageView?
  let imageSize = CGFloat(75)
  let margin = CGFloat(3)
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  init(item: TomeInventoryItem, coder aDecoder: NSCoder!) {
    self.item = item
    super.init(coder: aDecoder)
    buildSubviews()
  }
  
  init(item: TomeInventoryItem, frame: CGRect) {
    self.item = item
    super.init(frame: frame)
    buildSubviews()
  }
  
  func buildSubviews() {
    var y = CGFloat(0)
    let itemWidth = imageSize + 2 * margin
    if let name = item.itemData["name"].asString {
      
      for property in item.properties {
        let propertyView = TomeInventoryItemPropertyView(
          item: item,
          property: property,
          frame: CGRect(
            x: itemWidth,
            y: y + margin,
            width: frame.width - margin - itemWidth,
            height: 50.0))
        addSubview(propertyView)
        y += propertyView.frame.height + margin
      }
      if item.properties.count > 0 {
        showsProperties = true
        buildItemImage()
      }
    }
    let height = showsProperties ? max(y + margin, imageSize + 2 * margin) : 0
    frame = CGRect(
      x: frame.origin.x,
      y: frame.origin.y,
      width: frame.width,
      height: height)
    backgroundColor = UIColor(
      red: CGFloat(211.0/256.0),
      green: CGFloat(191.0/256.0),
      blue: CGFloat(129.0/256.0),
      alpha: 1)
  }
  
  func buildItemImage() {
    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
    dispatch_async(dispatch_get_global_queue(priority, 0)) {
      let imageData = NSData(contentsOfURL: self.item.imageURL)
      dispatch_async(dispatch_get_main_queue()) {
        // update some UI
        if imageData != nil {
          let image = UIImage(data: imageData!)
          let y = max(self.margin, (self.frame.size.height - self.imageSize) / 2)
          let imageFrame = CGRect(x: self.margin, y: y, width: self.imageSize, height: self.imageSize)
          self.imageView = UIImageView(frame: imageFrame)
          self.imageView!.image = image
          self.addSubview(self.imageView!)
        }
      }
    }
  }
  
  func tomeInventoryItemPropertyAtLocation(location:CGPoint)
    -> TomeInventoryItemProperty? {
    for subview in subviews {
      if !subview.isKindOfClass(TomeInventoryItemPropertyView) {
        continue
      }
      let CandidateView = subview as TomeInventoryItemPropertyView
      if CandidateView.frame.contains(location) {
        return CandidateView.property
      }
    }
    return nil
  }
}
