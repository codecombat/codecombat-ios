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

//The language provider is responsible for parsing files into languages
class LanguageProvider {
  var mutex:Bool = false //currently does nothing, learn how iOS mutexes work
  var scope:[String:String] = Dictionary<String,String>()
  
  func getLanguage(id:String) -> Language? {
    if let lang = languageFromScope(id) {
      return lang
    } else {
      return languageFromFile(id)
    }
  }
  
  func languageFromScope(id:String) -> Language? {
    let fileName = scope[id]
    if fileName != nil {
      return languageFromFile(fileName!)
    } else {
      return nil
    }
  }
  
  func languageFromFile(languageFileName:String) -> Language? {
    let languageFilePath = NSBundle.mainBundle().pathForResource(languageFileName, ofType: "tmLanguageJSON")
    let error:NSErrorPointer = nil
    let languageFileContents = String.stringWithContentsOfFile(languageFilePath!, encoding: NSUTF8StringEncoding, error: error)
    if error == nil || languageFileContents == nil {
      return nil
    }
    
    let languageFileJSON = JSON.parse(languageFileContents!)
    return parseLanguageFileJSON(languageFileJSON)
  }
  
  private func parseLanguageFileJSON(data:JSON) -> Language? {
    let newUnpatchedLanguage = UnpatchedLanguage()
    if let fileTypesArray = data["fileTypes"].asArray {
      for fileType in fileTypesArray {
        newUnpatchedLanguage.fileTypes.append(fileType.asString!)
      }
    }
    newUnpatchedLanguage.firstLineMatch = data["firstLineMatch"].asString
    newUnpatchedLanguage.scopeName = data["scopeName"].asString!
    if let repository = data["repository"].asDictionary {
      for (patternName, pattern) in repository {
        newUnpatchedLanguage.repository[patternName] = parsePattern(pattern)
      }
    }
    
    if let patterns = data["patterns"].asArray {
      //parse the root pattern here
      let rootPattern = Pattern()
      for pattern in patterns {
        rootPattern.patterns.append(parsePattern(pattern))
      }
      newUnpatchedLanguage.rootPattern = rootPattern
    }
    return Language(lang: newUnpatchedLanguage)
  }
  
  private func parsePattern(data:JSON) -> Pattern {
    let pattern = Pattern()
    return pattern
  }
  
  /*
  
  func parseJSONSyntaxRule(ruleData:JSON) -> SyntaxRule {
    let rule = SyntaxRule()
    rule.comment = ruleData["comment"].asString
    rule.disabled = ruleData["disabled"].asInt == 1 ? true : false
    rule.isInclude = ruleData["include"].isString
    rule.includePath = ruleData["include"].asString
    rule.name = ruleData["name"].asString
    rule.match = ruleData["match"].asString
    rule.begin = ruleData["begin"].asString
    rule.end = ruleData["end"].asString
    rule.contentName = ruleData["contentName"].asString
    if let captures = ruleData["captures"].asDictionary {
      rule.captures = Dictionary<String, SyntaxCapture>()
      for (captureNumber, captureData) in captures {
        let capture = SyntaxCapture()
        capture.name = captureData["name"].asString
        rule.captures![captureNumber] = capture
      }
    }
    if let beginCaptures = ruleData["beginCaptures"].asDictionary {
      rule.beginCaptures = Dictionary<String, SyntaxCapture>()
      for (captureNumber, captureData) in beginCaptures {
        let capture = SyntaxCapture()
        capture.name = captureData["name"].asString
        rule.beginCaptures![captureNumber] = capture
      }
    }
    if let endCaptures = ruleData["endCaptures"].asDictionary {
      rule.endCaptures = Dictionary<String, SyntaxCapture>()
      for (captureNumber, captureData) in endCaptures {
        let capture = SyntaxCapture()
        capture.name = captureData["name"].asString
        rule.endCaptures![captureNumber] = capture
      }
    }
    if let patterns = ruleData["patterns"].asArray {
      rule.patterns = Array<SyntaxRule>()
      for patternData in patterns {
        let pattern = parseJSONSyntaxRule(patternData)
        rule.patterns!.append(pattern)
      }
    }
    return rule
  }
  */
  
}

class UnpatchedLanguage {
  var fileTypes:[String] = []
  var firstLineMatch:String!
  var rootPattern:Pattern!
  var repository:[String:Pattern] = Dictionary<String,Pattern>()
  var scopeName:String = ""

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
