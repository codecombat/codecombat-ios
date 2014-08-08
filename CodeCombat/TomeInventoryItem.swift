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
      for (anotherPropIndex, anotherProp) in propertiesData {
        if anotherProp["name"].asString! == prop.asString! {
          properties.append(TomeInventoryItemProperty(propertyData: anotherProp, primary: true))
          break
        }
      }
    }
    for (propIndex, prop) in itemData["moreProgrammableProperties"] {
      for (anotherPropIndex, anotherProp) in propertiesData {
        if anotherProp["name"].asString! == prop.asString! {
          properties.append(TomeInventoryItemProperty(propertyData: anotherProp, primary: false))
          break
        }
      }
    }
  }
}
