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
  
  init() {
    
  }
  func description() -> String {
    if regex == nil {
      return "nil"
    }
    return "\(regex.expression())  // \(lastIndex), \(lastFound)"
  }
  
  func find(data:NSString, pos:Int) -> OnigResult? {
    if lastIndex > pos {
      lastFound = 0
    }
    lastIndex = pos
    let result = regex.search(data, start: Int32(lastFound))
    return result
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

class LanguageParser {
  var language:Language!
  var data:NSString!
  let maxIterations = 10000
  
  init(scope:String, data:NSString, provider:LanguageProvider) {
    let lang = provider.getLanguage(scope)
    if lang != nil {
      language = lang
      self.data = data
    }
  }
  
  func parse() -> DocumentNode {
    let rootNode = DocumentNode()
    rootNode.sourceText = data
    rootNode.name = language.scopeName
    var iterations = maxIterations
    for var i = 0; i < data.length && iterations > 0; iterations-- {
      //Not instituting caching mechanics until later
      var newLineLocation = data.rangeOfCharacterFromSet(NSCharacterSet.newlineCharacterSet(), options: nil, range: NSRange(location: i, length: data.length - i)).location
      
      
    }
    return rootNode
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
  var cachedData:NSString!
  var cachedPattern:Pattern!
  var cachedPatterns:[Pattern] = []
  var cachedMatch:OnigResult!
  var hits:Int = 0
  var misses:Int = 0
  
  func tweak(l:Language) {
    owner = l
    name = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    for pattern in patterns {
      pattern.tweak(l)
    }
  }
  
  func cache(data:NSString, position:Int) -> (pat:Pattern?, result:OnigResult?) {
    if cachedData === data {
      if cachedMatch == nil {
        return (nil,nil)
      }
      if cachedMatch.bodyRange().location >= position && cachedPattern.cachedPattern != nil {
        hits++
        return (cachedPattern, cachedMatch)
      }
    } else {
      cachedPatterns = []
    }
    if cachedPatterns.count == 0 {
      for pattern in patterns {
        cachedPatterns.append(pattern)
      }
    }
    misses++
    var pat:Pattern? = nil
    var result:OnigResult?
    if match.regex != nil {
      pat = self
      result = match.find(data, pos: position)
    } else if begin.regex != nil {
      pat = self
      result = begin.find(data, pos: position)
    } else if include != nil {
      let includePrefix = Array(include)[0]
      if includePrefix == "#" {
        let key = include.substringFromIndex(include.startIndex.successor())
        let includePattern = owner.repository[key]
        if includePattern != nil {
          (pat, result) = includePattern!.cache(data, position: position)
        } else {
          println("The pattern \(key) wasn't found!")
        }
      } else if includePrefix == "$" {
        println("Include prefix $ isn't handled")
        //Also handle alternative languages
      }
    } else {
      (pat, result) = firstMatch(data, pos: position)
    }
    cachedData = data
    cachedMatch = result
    cachedPattern = pat
    return (pat, result)
  }
  
  func firstMatch(data:NSString, pos:Int) -> (pat:Pattern?, ret:OnigResult?) {
    var startIndex = -1
    for var i=0; i < patterns.count; {
      let (ip, im) = patterns[i].cache(data, position: pos)
      if im != nil {
        if startIndex < 0 || startIndex > im!.bodyRange().location {
          startIndex = im!.bodyRange().location
          var pat = ip
          var ret = im
          if startIndex == pos {
            break
          }
        }
        i++
      } else {
        //pop the cached pattern
        cachedPatterns.removeAtIndex(i)
      }
    }
    return (nil, nil)
  }
  
  func createCaptureNodes(data:NSString, pos:Int, d:NSString, result:OnigResult, parent:DocumentNode, capt:[Capture]) {
    //I think the captures are probably unnecessary and can be refactored out
    var ranges:[NSRange] = []
    var parentIndex:[Int] = []
    var parents:[DocumentNode] = []
    for var i:UInt = 0; i < result.count(); i++ {
      ranges.insert(result.rangeAt(i), atIndex: Int(i))
      if i < 2 { //what is the significance of the first two entries?
        parents.insert(parent, atIndex: Int(i))
        continue
      }
      let range = ranges[Int(i)]
      for var j = i - 1; j >= 0; j-- {
        if NSIntersectionRange(ranges[Int(j)], range).length == range.length {
          parentIndex[Int(i)] = Int(j)
          break
        }
      }
    }
    for capture in capt {
      var captureKey = capture.key
      // I think due to the ranges being nil and the captures perhaps not, this might screw up
      if captureKey >= parents.count || ranges[captureKey].location == NSNotFound {
        continue
      }
      let child = DocumentNode()
      child.name = capture.name
      child.range = ranges[captureKey]
      child.sourceText = data
      parents[captureKey] = child
      if captureKey == 0 {
        parent.children.append(child)
        continue
      }
      var p:DocumentNode! = nil
      while p == nil {
        captureKey = parentIndex[captureKey]
        p = parents[captureKey]
      }
      p.children.append(child)
    }
  }
}
