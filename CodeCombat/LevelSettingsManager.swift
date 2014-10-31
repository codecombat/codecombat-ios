//
//  LevelSettingsManager.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 10/31/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

private let levelSettingsManagerSharedInstance = LevelSettingsManager()
import UIKit

enum CodeLanguage {
  case Python
  case Javascript
}

enum LevelName:String {
  case TheRaisedSword = "the-raised-sword"
  case TrueNames = "true-names"
  case NewSight = "new-sight"
  case Unknown = "unknown"
}
class LevelSettingsManager {
  var level:LevelName = .TheRaisedSword
  var language:CodeLanguage = .Python
  class var sharedInstance: LevelSettingsManager {
    return levelSettingsManagerSharedInstance
  }
  
}
