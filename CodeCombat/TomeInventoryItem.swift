//
//  TomeInventoryItem.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

struct TomeInventoryItem {
  let itemData: JSON
  var properties: [TomeInventoryItemProperty] = []
  
  init(itemData: JSON, propertiesData: JSON) {
    self.itemData = itemData
    for (propIndex, prop) in itemData["programmableProperties"] {
      properties.append(TomeInventoryItemProperty(propertyData: propertiesData[prop.asString!], primary: true))
    }
    for (propIndex, prop) in itemData["moreProgrammableProperties"] {
      properties.append(TomeInventoryItemProperty(propertyData: propertiesData[prop.asString!], primary: false))
    }
  }
}
