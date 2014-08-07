//
//  TomeInventoryItem.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

struct TomeInventoryItem {
  let name = ""
  let slot = ""
  var properties: [TomeInventoryItemProperty] = []
  
  init(name: String, slot: String) {
    self.name = name
    self.slot = slot
  }
  
  mutating func addProperty(property:TomeInventoryItemProperty) {
    self.properties.append(property)
  }
}
