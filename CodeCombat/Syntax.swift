//
//  Syntax.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/12/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
//http://docs.sublimetext.info/en/latest/extensibility/syntaxdefs.html
//https://github.com/quiqueg/Swift-Sublime-Package/blob/master/Syntaxes/Swift.JSON-tmLanguage
//http://manual.macromates.com/en/language_grammars

//To convert the tmLanguage files, convert using AAAPackageDev to YAML then use a YAML parser to convert to JSON

class SyntaxCapture {
  var name:String!
}

class SyntaxRule {
  var isInclude:Bool = false
  var includePath:String?
  var name:String!
  var match:String!
  var begin:String?
  var end:String?
  var contentName:String?
  var captures:[String:SyntaxCapture]?
  var beginCaptures:[String:SyntaxCapture]?
  var endCaptures:[String:SyntaxCapture]?
  var patterns:[SyntaxRule]?
}

class Syntax {
  var name:String!
  var scopeName:String!
  var repository:[String:SyntaxRule] = Dictionary<String,SyntaxRule>()
  var patterns:[SyntaxRule] = []
  
  func addPattern(pattern:SyntaxRule) {
    patterns.append(pattern)
  }
  
  func addRuleToRepository(ID:String, pattern:SyntaxRule) {
    repository[ID] = pattern
  }
  
  func resolveSelfInclude() -> Syntax {
    return self
  }
  func resolveLanguageInclude() -> Syntax {
    return self //Fix this eventually
  }
  func resolveIncludeAtPath(repositoryRuleID:String) -> SyntaxRule {
    //Strip the # from the ID
    let substring = repositoryRuleID.substringFromIndex(repositoryRuleID.startIndex.successor())
    return repository[substring]! //Will crash if reference doesn't exist, perhaps make optional
  }
}


func parseJSONIntoSyntax(syntaxData:JSON) -> Syntax {
  let syntaxObject = Syntax()
  //parse top level elements
  syntaxObject.name = syntaxData["name"].asString
  syntaxObject.scopeName = syntaxData["scopeName"].asString
  if let repository = syntaxData["repository"].asDictionary {
    for (ruleID,ruleData) in repository {
      let rule = parseJSONSyntaxRule(ruleData)
      syntaxObject.addRuleToRepository(ruleID, pattern: rule)
    }
  }
  if let patterns = syntaxData["patterns"].asArray {
    for patternData in patterns {
      let pattern = parseJSONSyntaxRule(patternData)
      syntaxObject.addPattern(pattern)
    }
  }
  return syntaxObject
}

func parseJSONSyntaxRule(ruleData:JSON) -> SyntaxRule {
  let rule = SyntaxRule()
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

/*
let swiftSyntaxJSONData = String.stringWithContentsOfFile(NSBundle.mainBundle().pathForResource("javascript", ofType: "json"), encoding: NSUTF8StringEncoding, error: nil)!
let swiftJSON = JSON.parse(swiftSyntaxJSONData)
let start = NSDate()
let swiftSyntax = parseJSONIntoSyntax(swiftJSON)
*/
