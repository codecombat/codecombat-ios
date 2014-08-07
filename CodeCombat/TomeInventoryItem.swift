//
//  TomeInventoryItem.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

class TomeInventoryItem {
  var name = ""
  var spells: [TomeInventoryItemSpell] = []
  
  func addSpell(spell:TomeInventoryItemSpell) {
    spells.append(spell)
  }
}
