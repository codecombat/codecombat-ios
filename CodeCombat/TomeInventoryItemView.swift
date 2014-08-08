//
//  TomeInventoryItemView.swift
//  CodeCombat
//
//  Created by Nick Winter on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

import UIKit
import QuartzCore

class TomeInventoryItemView: UIView {
  
  var item: TomeInventoryItem?

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
    if let name = item?.itemData["name"].asString {
      println("Gotta build subviews for \(name)!")
      var label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width / 2.0, height: frame.height))
      label.text = name
      label.textColor = UIColor(white: 1, alpha: 1)
      addSubview(label)
    }
  }
}
