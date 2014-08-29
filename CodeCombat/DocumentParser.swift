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
      //find(b []byte, n int, offset int) https://github.com/moovweb/rubex/blob/go1/regex.go#L169
      //ret := r.re.FindStringSubmatchIndex(data[r.lastFound:])
      //match = re.find(b, len(b), 0)
      if result == nil {
        break
        //i have no idea what the rubex ret[0] means
        //the match is beginning, end
        
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

//The language provider is responsible for parsing files into languages
class LanguageProvider {
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
    //TODO: Verify that this doesn't screw up the app, I changed it from mainBundle for test compatibility
    let languageFilePath = NSBundle(forClass: LanguageProvider.self).pathForResource(languageFileName, ofType: "tmLanguageJSON")
    if languageFilePath == nil {
      return nil
    }
    let error:NSErrorPointer = nil
    let languageFileContents = String.stringWithContentsOfFile(languageFilePath!, encoding: NSUTF8StringEncoding, error: error)
    if error != nil || languageFileContents == nil {
      return nil
    }
    
    let languageFileJSON = JSON.parse(languageFileContents!)
    let parsedLanguage = parseLanguageFileJSON(languageFileJSON)
    if parsedLanguage != nil {
      scope[parsedLanguage!.scopeName] = languageFileName
    }
    return parsedLanguage
  }
  
  private func parseLanguageFileJSON(data:JSON) -> Language? {
    let lang = Language()
    if let fileTypesArray = data["fileTypes"].asArray {
      for fileType in fileTypesArray {
        lang.fileTypes.append(fileType.asString!)
      }
    }
    lang.firstLineMatch = data["firstLineMatch"].asString
    lang.scopeName = data["scopeName"].asString!
    if let repository = data["repository"].asDictionary {
      for (patternName, pattern) in repository {
        lang.repository[patternName] = parsePattern(pattern)
      }
    }
    
    if let patterns = data["patterns"].asArray {
      //parse the root pattern here
      let rootPattern = Pattern()
      for pattern in patterns {
        rootPattern.patterns.append(parsePattern(pattern))
      }
      lang.rootPattern = rootPattern
    }
    return lang
  }
  
  private func parsePattern(data:JSON) -> Pattern {
    let pattern = Pattern()
    pattern.name = data["name"].asString
    pattern.disabled = data["disabled"].asBool
    pattern.include = data["include"].asString
    if let matchData = data["match"].asString {
      let match = Regex()
      //TODO: Profile that compiling all of the regexes on the fly is performant
      match.regex = OnigRegexp.compile(matchData)
      pattern.match = match
    }
    if let captures = data["captures"].asDictionary {
      for (captureNumber, captureData) in captures {
        let capture = Capture(key: captureNumber.toInt()!)
        capture.name = captureData["name"].asString
        pattern.captures.append(capture)
      }
      pattern.captures = sorted(pattern.captures, {$0.key < $1.key })
    }
    if let beginData = data["begin"].asString {
      let begin = Regex()
      begin.regex = OnigRegexp.compile(beginData)
      pattern.begin = begin
    }
    if let beginCaptures = data["beginCaptures"].asDictionary {
      for (captureNumber, captureData) in beginCaptures {
        let capture = Capture(key: captureNumber.toInt()!)
        capture.name = captureData["name"].asString
        pattern.beginCaptures.append(capture)
      }
      pattern.beginCaptures = sorted(pattern.beginCaptures, {$0.key < $1.key })
    }
    if let endData = data["end"].asString {
      let end = Regex()
      end.regex = OnigRegexp.compile(endData)
      pattern.end = end
    }
    if let endCaptures = data["endCaptures"].asDictionary {
      for (captureNumber, captureData) in endCaptures {
        let capture = Capture(key: captureNumber.toInt()!)
        capture.name = captureData["name"].asString
        pattern.endCaptures.append(capture)
      }
      pattern.endCaptures = sorted(pattern.endCaptures, {$0.key < $1.key })
    }
    if let patterns = data["patterns"].asArray {
      for patternData in patterns {
        let nestedPattern = parsePattern(patternData)
        pattern.patterns.append(nestedPattern)
      }
    }
    return pattern
  }
}

class Language {
  var fileTypes:[String] = []
  var firstLineMatch:String!
  var rootPattern:Pattern!
  var repository:[String:Pattern] = Dictionary<String,Pattern>()
  var scopeName:String = ""

  func tweak() {
    rootPattern.tweak(self)
    for (patternID, pattern) in repository {
      pattern.tweak(self)
    }
  }
}

class Capture {
  var key:Int
  var name:String!
  init(key:Int) {
    self.key = key
  }
}

class Pattern {
  //change the implicitly unwrapped optionals once construction is understood
  var name:String!
  var disabled:Bool! = false
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
