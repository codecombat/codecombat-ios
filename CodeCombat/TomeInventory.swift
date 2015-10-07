//
//  TomeInventory.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/10/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

class TomeInventory: NSObject {
  //can use dynamic keyword for KVO
  var items: [TomeInventoryItem] = []
  
  override init() {
    super.init()
  }
  
  convenience init(itemsData: JSON, propertiesData:JSON) {
    self.init()
    for (_, itemData) in itemsData {
      let item = TomeInventoryItem(itemData: itemData, propertiesData: propertiesData)
      addInventoryItem(item)
    }
  }
  
  func addInventoryItem(item: TomeInventoryItem) {
    items.append(item)
  }
}