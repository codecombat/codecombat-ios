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
  case DungeonsOfKithgard = "dungeons-of-kithgard"
  case GemsInTheDeep = "gems-in-the-deep"
  case ShadowGuard = "shadow-guard"
  case KounterKithwise = "kounter-kithwise"
  case CrawlwaysOfKithgard = "crawlways-of-kithgard"
  case ForgetfulGemsmith = "forgetful-gemsmith"
  case TrueNames = "true-names"
  case FavorableOdds = "favorable-odds"
  case TheRaisedSword = "the-raised-sword"
  case TheFirstKithmaze = "the-first-kithmaze"
  case HauntedKithmaze = "haunted-kithmaze"
  case DescendingFurther = "descending-further"
  case TheSecondKithmaze = "the-second-kithmaze"
  case DreadDoor = "dread-door"
  case KnownEnemy = "known-enemy"
  case MasterOfNames = "master-of-names"
  case LowlyKithmen = "lowly-kithmen"
  case ClosingTheDistance = "closing-the-distance"
  case TacticalStrike = "tactical-strike"
  case TheFinalKithmaze = "the-final-kithmaze"
  case TheGauntlet = "the-gauntlet"
  case KithgardGates = "kithgard-gates"
  case CavernSurvival = "cavern-survival"
  case DefenseOfPlainswood = "defense-of-plainswood"
  case WindingTrail = "winding-trail"
  case ThornbushFarm = "thornbush-farm"
  case BackToBack = "back-to-back"
  case OgreEncampment = "ogre-encampment"
  case WoodlandCleaver = "woodland-cleaver"
  case ShieldRush = "shield-rush"
  case PeasantProtection = "peasant-protection"
  case MunchkinSwarm = "munchkin-swarm"
  case Coinucopia = "coinucopia"
  case CopperMeadows = "copper-meadows"
  case DropTheFlag = "drop-the-flag"
  case DeadlyPursuit = "deadly-pursuit"
  case RichForager = "rich-forager"
  case MultiplayerTreasureGrove = "multiplayer-treasure-grove"
  case DuelingGrounds = "dueling-grounds"
  case Unknown = "unknown"
}
class LevelSettingsManager {
  var level:LevelName = .TheRaisedSword
  var language:CodeLanguage = .Python
  class var sharedInstance: LevelSettingsManager {
    return levelSettingsManagerSharedInstance
  }
  
}
