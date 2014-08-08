//
//  TomeInventoryItemView.swift
//  CodeCombat
//
//  Created by Nick Winter on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

class TomeInventoryItemView: UIView {
  
  var item: TomeInventoryItem?
  var showsProperties = false

  func baseInit(item: TomeInventoryItem) {
    self.item = item
    buildSubviews()
  }
  
  required init(coder aDecoder: NSCoder!) {
    super.init(coder: aDecoder)
  }
  
  init(item: TomeInventoryItem, coder aDecoder: NSCoder!) {
    super.init(coder: aDecoder)
    baseInit(item)
  }

  init(item: TomeInventoryItem, frame: CGRect) {
    super.init(frame: frame)
    baseInit(item)
  }
  
  func buildSubviews() {
    let Margin = CGFloat(3.0)
    var y = CGFloat(0)
    if let name = item?.itemData["name"].asString {
      if let properties = item?.properties {
        for property in properties {
          let propertyView = TomeInventoryItemPropertyView(item: item!, property: property, frame: CGRect(x: frame.width / 2.0 + Margin, y: y + Margin, width: frame.width / 2.0 - 2 * Margin, height: 50.0))
          addSubview(propertyView)
          y += propertyView.frame.height + Margin
        }
        if properties.count > 0 {
          var label = UILabel(frame: CGRect(x: Margin, y: Margin, width: frame.width / 2.0 - 2 * Margin, height: frame.height - 2 * Margin))
          label.text = name
          label.textColor = UIColor.blackColor()
          label.sizeToFit()
          label.frame = CGRect(x: label.frame.origin.x, y: CGFloat((y + Margin - label.frame.height) / 2.0), width: label.frame.width, height: label.frame.height)
          addSubview(label)
          showsProperties = true
        }
      }
    }
    frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: showsProperties ? y + Margin : 0)
    backgroundColor = UIColor(red: CGFloat(211.0/256.0), green: CGFloat(191.0/256.0), blue: CGFloat(129.0/256.0), alpha: 1)
    //211	191	129
  }
  
  func tomeInventoryItemPropertyAtLocation(location:CGPoint) -> TomeInventoryItemProperty? {
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
