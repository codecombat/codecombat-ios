//
//  DocumentNode.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/27/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

class DocumentNode {
  var range:NSRange = NSRange(location: 0, length: 0)
  var name:String! = ""
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
    if range.location == NSNotFound || sourceText == nil {
      return ""
    }
    if indent == nil {
      indent = ""
    }
    let begin = range.location
    let end = range.location + range.length
    let nodeName = name == nil || name == "" ? "(no name)" : name
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
  
  func updateRange() -> NSRange {
    for child in children {
      let currentRange = child.updateRange()
      if currentRange.location < range.location {
        range.location = currentRange.location
      }
      if NSMaxRange(currentRange) > NSMaxRange(range) {
        range.length = NSMaxRange(currentRange) - range.location
      }
    }
    return range
  }
  
  func adjust(position:Int, delta:Int) {
    if range.location >= position {
      range.location += delta
    } else if position + delta - range.location < 0 {
      range.location += position + delta - range.location
    }
    if NSMaxRange(range) >= position {
      range.length += delta
    } else if position + delta - NSMaxRange(range) < 0 {
      range.length += position + delta - NSMaxRange(range)
    }
    for child in children {
      child.adjust(position, delta: delta)
    }
  }
  
}