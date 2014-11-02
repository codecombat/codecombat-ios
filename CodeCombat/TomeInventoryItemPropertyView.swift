//
//  TomeInventoryItemPropertyView.swift
//  CodeCombat
//
//  Created by Nick Winter on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

class TomeInventoryItemPropertyView: UIButton {
  
  var item: TomeInventoryItem!
  var property: TomeInventoryItemProperty!
  
  func baseInit(item: TomeInventoryItem, property: TomeInventoryItemProperty) {
    self.item = item
    self.property = property
    buildSubviews()
    addTarget(self, action: Selector("onTapped:"), forControlEvents: .TouchUpInside)
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  init(item: TomeInventoryItem,
    property: TomeInventoryItemProperty, coder aDecoder: NSCoder!) {
    super.init(coder: aDecoder)
    baseInit(item, property: property)
  }
  
  init(item: TomeInventoryItem,
    property: TomeInventoryItemProperty, frame: CGRect) {
    super.init(frame: frame)
    baseInit(item, property: property)
  }
  
  func buildSubviews() {
    let padding = CGFloat(5.0)
    if let name = property?.propertyData["name"].asString {
      var label = UILabel(
        frame: CGRect(
          x: padding,
          y: padding,
          width: frame.width - 2 * padding,
          height: frame.height))
      label.text = name
      label.textColor = UIColor.blackColor()
      addSubview(label)
      label.sizeToFit()
      frame = CGRect(
        x: frame.origin.x,
        y: frame.origin.y,
        width: frame.width,
        height: label.frame.height + 2 * padding)
      //backgroundColor = UIColor(red: 225.0 / 255.0, green: 219.0 / 255.0, blue: 198.0 / 255.0, alpha: 1.0)
      backgroundColor = UIColor.clearColor()
    }
  }
  
  func onTapped(sender: TomeInventoryItemView) {
    var docView = TomeInventoryItemPropertyDocumentationView(item: item, property: property, frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    var docViewController = UIViewController()
    docViewController.view = docView
    var popover = UIPopoverController(contentViewController: docViewController)
    popover.presentPopoverFromRect(frame, inView: superview!.superview!, permittedArrowDirections: .Down | .Up, animated: true)
    println("tapped \(self.item.name) \(self.property.name)")
  }
}
