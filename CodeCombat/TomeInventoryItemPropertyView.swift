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
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  init?(item: TomeInventoryItem,
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
      let dotLabel = UILabel(
        frame: CGRect(
          x: padding,
          y: padding,
          width: 25,
          height: frame.height))
      dotLabel.font = UIFont(name: "Menlo", size: 12)
      dotLabel.text = " ● "
      dotLabel.textColor = UIColor(red: 117.0 / 255.0, green: 110.0 / 255.0, blue: 90.0 / 255.0, alpha: 1.0)
      dotLabel.sizeToFit()
      let label = UILabel(
        frame: CGRect(
          x: padding + dotLabel.frame.width,
          y: padding,
          width: frame.width - 2 * padding - dotLabel.frame.width,
          height: frame.height))
      label.font = dotLabel.font
      label.text = name
      label.textColor = UIColor(red: 26.0 / 255.0, green: 20.0 / 255.0, blue: 12.0 / 255.0, alpha: 1.0)
      addSubview(dotLabel)
      addSubview(label)
      label.sizeToFit()
      frame = CGRect(
        x: frame.origin.x,
        y: frame.origin.y,
        width: frame.width,
        height: label.frame.height + 2 * padding)
      backgroundColor = UIColor(red: 225.0 / 255.0, green: 219.0 / 255.0, blue: 198.0 / 255.0, alpha: 1.0)
    }
  }
  
  func onTapped(sender: TomeInventoryItemView) {
    let docView = TomeInventoryItemPropertyDocumentationView(item: item, property: property, frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let docViewController = UIViewController()
    docViewController.view = docView
    let popover = UIPopoverController(contentViewController: docViewController)
    popover.presentPopoverFromRect(frame, inView: superview!.superview!, permittedArrowDirections: [.Down, .Up], animated: true)
    print("tapped \(self.item.name) \(self.property.name)")
  }
}
