//
//  LevelSettingsManager.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 10/31/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

private let levelSettingsManagerSharedInstance = LevelSettingsManager()
import UIKit

enum CodeLanguage:String {
  case Python = "python"
  case Javascript = "javascript"
}

enum LevelName:String {
  case TheRaisedSword = "the-raised-sword"
  case TrueNames = "true-names"
  case FavorableOdds = "favorable-odds"
  case NewSight = "new-sight"
  case KnownEnemy = "known-enemy"
  case MasterOfNames = "master-of-names"
  case LowlyKithmen = "lowly-kithmen"
  case ClosingTheDistance = "closing-the-distance"
  case TacticalStrike = "tactical-strike"
  case TheFinalKithmaze = "the-final-kithmaze"
  case TheGauntlet = "the-gauntlet"
  case KithgardGates = "kithgard-gates"
  case Unknown = "unknown"
}
class LevelSettingsManager {
  var level:LevelName = .TheRaisedSword
  var language:CodeLanguage = .Python
  class var sharedInstance: LevelSettingsManager {
    return levelSettingsManagerSharedInstance
  }
  
}
