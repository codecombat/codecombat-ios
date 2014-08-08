//
//  TomeInventoryItemSpell.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

struct TomeInventoryItemProperty {
  let propertyData: JSON
  let primary: Bool
  
  init(propertyData: JSON, primary: Bool) {
    self.propertyData = propertyData
    self.primary = primary
  }
}

//struct TomeInventoryItemProperty {
//  let name = ""
//  var codeLanguages: [String] = []
//  let type = ""
//  var description = ""  // actually multiplex by codeLanguage
//  var args: [TomeInventoryItemFunctionArgument] = []
//  var owner = "this"
//  var example = ""   // actually multiplex by codeLanguage
//  var snippets: [String] = []
//  var returns: TomeInventoryItemFunctionReturnValue? = nil
//  
//  init(name: String="", codeLanguages: [String]=[], type: String="", description: String="", args: [TomeInventoryItemFunctionArgument]=[], owner: String="this", example: String="", snippets: [String]=[], returns: TomeInventoryItemFunctionReturnValue?=nil) {
//    self.name = name
//    self.codeLanguages = codeLanguages
//    self.type = type
//    self.description = description
//    self.args = args
//    self.owner = owner
//    self.example = example
//    self.snippets = snippets
//    self.returns = returns
//  }
//}
//
//struct TomeInventoryItemFunctionArgument {
//  let name = ""
//  let type = ""
//  var example = ""  // actually multiplex by codeLanguage
//  var description = ""  // actually multiplex by codeLanguage
//  //var defaultValue = ""  // could be any type; do we even want to keep this? also, it's named "default" in the schema
//}
//
//struct TomeInventoryItemFunctionReturnValue {
//  let type = ""
//  var example = ""  // actually multiplex by codeLanguage
//  var description = ""  // actually multiplex by codeLanguage
//}
