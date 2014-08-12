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
  var name: String { //What do we do about schemas?
    return propertyData["name"].toString(pretty: false)
  }
  
  func codeSnippetForLanguage(language:String) -> String? {
    let Snippet = propertyData["snippets"][language]["code"]
    if Snippet.isString {
      return Snippet.toString(pretty: false)
    } else {
      return nil
    }
  }
  
  subscript(key:String) -> AnyObject? {
    return propertyData[key]
  }

}