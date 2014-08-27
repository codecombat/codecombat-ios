//
//  DocumentParser.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/27/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

typealias MatchObject = [Int]

class Regex {
  var regex:OnigRegexp!
  var lastIndex:Int = 0
  var lastFound:Int = 0
  
  func description() -> String {
    if regex == nil {
      return "nil"
    }
    return "\(regex.expression())  // \(lastIndex), \(lastFound)"
  }
  
  func find(data:NSString, pos:Int) -> MatchObject {
    if lastIndex > pos {
      lastFound = 0
    }
    lastIndex = pos
    while lastFound < data.length {
      let result = regex.search(data, start: Int32(lastFound))
      if result == nil {
        break
        //i have no idea what the rubex ret[0] means
        
      } else if result.rangeAt(0).location < pos {
        let wtfrubex = result.rangeAt(0).location
        if wtfrubex == 0 {
          lastFound++
        } else {
          lastFound += wtfrubex
        }
        continue
      }
      var matchObj:MatchObject = []
      for var i:UInt=0; i < result.count(); i++ {
        matchObj.append(result.rangeAt(i).location)
      }
      //missing fix object here, probably nonfunctional
      return matchObj
    }
    return []
  }
  
}

class Language {
  var unpatchedLanguage:UnpatchedLanguage
  init(lang:UnpatchedLanguage) {
    unpatchedLanguage = lang
  }
}

class LanguageProvider {
  var mutex:Bool = false //currently does nothing, learn how iOS mutexes work
  var scope:[String:String] = Dictionary<String,String>()
}

class UnpatchedLanguage {
  var fileTypes:[String] = []
  var firstLineMatch:String!
  var rootPattern:RootPattern!
  
}

class Named {
  var name:String
  init(name:String) {
    self.name = name
  }
}

class Capture {
  var key:Int
  var named:Named!
  init(key:Int) {
    self.key = key
  }
}

class RootPattern {
  var pattern:Pattern
  init(pattern:Pattern) {
    self.pattern = pattern
  }
}

class Pattern {
  //change the implicitly unwrapped optionals once construction is understood
  var name:String!
  var include:String!
  var match:Regex!
  var captures:[Capture] = []
  var begin:Regex!
  var beginCaptures:[Capture] = []
  var end:Regex!
  var endCaptures:[Capture] = []
  var patterns:[Pattern] = []
  var owner:Language!
  var cachedData:String!
  var cachedPattern:Pattern!
  var cachedPatterns:[Pattern] = []
  var cachedMatch:[Int] = []
  var hits:Int = 0
  var misses:Int = 0
  
  func tweak(l:Language) {
    owner = l
    name = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    for pattern in patterns {
      pattern.tweak(l)
    }
  }
  
  /*func firstMatch(data:NSString, pos:Int) -> (pat:Pattern, ret:MatchObject) {
  var startIndex = -1
  for var i=0; i < cachedPatterns.count;; {
  
  }
  }*/
  
  
}
