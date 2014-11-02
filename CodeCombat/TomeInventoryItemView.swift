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
  let marginH = CGFloat(10)  // Left side to image, image to prop, prop to right padding
  let marginV = CGFloat(3)  // Between props
  let padding = CGFloat(30)  // Top, right, and bottom padding (left padding is just a weird hack)
  
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
    var y = padding
    let itemWidth = imageSize + 2 * marginH
    var propertyViews: [TomeInventoryItemPropertyView] = []
    if let name = item.itemData["name"].asString {
      for property in item.properties {
        let propertyView = TomeInventoryItemPropertyView(
          item: item,
          property: property,
          frame: CGRect(
            x: itemWidth,
            y: y + marginV,
            width: frame.width - padding - marginH - itemWidth,
            height: 50.0))
        addSubview(propertyView)
        y += propertyView.frame.height + marginV
        propertyViews.append(propertyView)
      }
      if item.properties.count > 0 {
        showsProperties = true
        y += marginV + padding
        buildItemImage()
      }
    }
    let minHeight = imageSize + 2 * (marginV + padding)
    let height = showsProperties ? max(y, minHeight) : 0
    if y < height {
      // Center the properties in the view.
      for propertyView in propertyViews {
        propertyView.frame.origin.y += (height - y) / CGFloat(propertyViews.count) / 2.0
      }
    }
    frame = CGRect(
      x: frame.origin.x,
      y: frame.origin.y,
      width: frame.width,
      height: height)
    let backgroundImage = UIImage(named: "tome_item_background")
    let background = UIImageView(image: backgroundImage)
    background.frame = CGRect(x: -30, y: 0, width: frame.width + 30, height: frame.height)
    insertSubview(background, atIndex: 0)
  }
  
  func buildItemImage() {
    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
    dispatch_async(dispatch_get_global_queue(priority, 0)) {
      let imageData = NSData(contentsOfURL: self.item.imageURL)
      dispatch_async(dispatch_get_main_queue()) {
        // update some UI
        if imageData != nil {
          let image = UIImage(data: imageData!)
          let y = max(self.marginV + self.padding, (self.frame.size.height - self.imageSize) / 2)
          let imageFrame = CGRect(x: self.marginH, y: y, width: self.imageSize, height: self.imageSize)
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
