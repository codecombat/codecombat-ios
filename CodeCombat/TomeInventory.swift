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
  
  init(itemsData: JSON, propertiesData:JSON) {
    super.init()
    for (i, itemData) in itemsData {
      let item = TomeInventoryItem(
        itemData: itemData,
        propertiesData: propertiesData)
      items.append(item)
    }
  }
}