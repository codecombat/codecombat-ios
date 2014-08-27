//
//  DocumentNode.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/27/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

class DocumentNode {
  var range:NSRange!
  var name:String = ""
  var children:[DocumentNode] = []
  var sourceText:NSString!
  var data:String {
    return sourceText.substringWithRange(range)
  }
  
  init() {
  
  }
  func description() -> String {
    return format(nil)
  }
  
  func format(var indent:String!) -> String {
    if range == nil || sourceText == nil {
      return ""
    }
    if indent == nil {
      indent = ""
    }
    let begin = range.location
    let end = range.location + range.length
    let nodeName = name == "" ? "(no name)" : name
    if children.count == 0 {
      return indent + "\(begin)-\(end): \(nodeName) - Data: \"\(data)\"\n"
    } else {
      var returnString = indent + "\(begin)-\(end): \"\(nodeName)\"\n"
      indent = indent + "\t"
      for child in children {
        returnString += child.format(indent)
      }
      return returnString
    }
  }
  
}