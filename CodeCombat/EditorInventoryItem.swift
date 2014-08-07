//
//  EditorInventoryItem.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

class EditorInventoryItem {
  var name = ""
  var spells: [EditorInventoryItemSpell] = []
  
  func addSpell(spell:EditorInventoryItemSpell) {
    spells.append(spell)
  }
}
