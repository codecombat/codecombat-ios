//
//  GameViewController.swift
//  CodeCombat
//
//  Created by Nick Winter on 10/24/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation
import WebKit

var autoLoggedIn: Bool = false  // Wish class variables were supported.

class GameViewController: UIViewController, UIActionSheetDelegate {
  var webManager = WebManager.sharedInstance
  var webView: WKWebView = WebManager.sharedInstance.webView!
  var playViewController: PlayViewController?
  var playLevelRoutePrefix = "/play/level/"

  override func viewDidLoad() {
    super.viewDidLoad()
    webView = WebManager.sharedInstance.webView!
    view.addSubview(webView)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("listenToNotifications"), name: "webViewDidFinishNavigation", object: nil)
  }
  
  func listenToNotifications() {
    delay(1, {
      self.webManager.subscribe(self, channel: "router:navigated", selector: Selector("onNavigated:"))
      self.webManager.subscribe(self, channel: "level:loading-view-unveiled", selector: Selector("onLevelStarted:"))
      self.webManager.subscribe(self, channel: "auth:logging-out", selector: Selector("onLogout"))
      //webManager.subscribe(self, channel: "supermodel:load-progress-changed", selector: Selector("onProgressUpdate:"))
    })
    
  }
  
  deinit {
    WebManager.sharedInstance.unsubscribe(self)
  }
  
  func onLogout() {
    webManager.clearCredentials()
    webManager.unsubscribe(self)
    NSNotificationCenter.defaultCenter().removeObserver(self)
    webManager.removeAllUserScripts()
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  private func loadLevel(levelSlug:String) {
    WebManager.sharedInstance.publish("router:navigate", event: ["route": "/play/level/\(levelSlug)"])
  }
  
  private func loadWorldMap() {
    WebManager.sharedInstance.publish("router:navigate", event: ["route": "/play"])
  }
  
  private func isRouteLevel(route: String) -> Bool {
    return route.rangeOfString(playLevelRoutePrefix, options: NSStringCompareOptions.LiteralSearch) != nil
  }
  
  private func routeLevelName(route:String) -> String {
    if !isRouteLevel(route) {
      return ""
    } else {
      let substringIndex = advance(route.startIndex, countElements(playLevelRoutePrefix))
      return route.substringFromIndex(substringIndex)
    }
  }
  
  private func updateFrame(route: String) {
    var webViewFrame = CGRectMake(0, 0, 1024, 768)  // Full-size
    if isRouteLevel(route) {
      let topBarHeight: CGFloat = 50
      webViewFrame = CGRectMake(0, 0, 1024, topBarHeight + 1024 * (589 / 924))  // Full-width Surface, preserving aspect ratio.
    }
    WebManager.sharedInstance.webView!.frame = webViewFrame
  }
  
  private func adjustPlayView(route: String) {
    if isRouteLevel(route) {
      let currentLevelName = routeLevelName(route)
      let mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
      playViewController = mainStoryboard.instantiateViewControllerWithIdentifier("PlayViewController") as? PlayViewController
      playViewController?.view  // Access this early to get it set up and listening for events.
      playViewController!.levelName = currentLevelName
      if let newLevel = LevelName(rawValue: currentLevelName) {
        LevelSettingsManager.sharedInstance.level = newLevel
      } else {
        LevelSettingsManager.sharedInstance.level = .Unknown
      }
      println("Created a playViewController for \(route)")
    }
    else {
      println("Route is not a level \(route), so dismissing playViewController \(playViewController), have presentedViewController \(presentedViewController)")
      LevelSettingsManager.sharedInstance.level = .Unknown
      if presentedViewController != nil {
        dismissViewControllerAnimated(false, completion: nil)
        playViewController = nil
        view.addSubview(webView)
      }
    }
  }
  
  func onNavigated(note: NSNotification) {
    println("onNavigated:", note)
    if let event = note.userInfo {
      let route = event["route"]! as String
      updateFrame(route)
      adjustPlayView(route)
    }
  }

  func onLevelStarted(note: NSNotification) {
    if presentedViewController != nil {
      println("Hmmm, trying to start level again?");
    } else {
      playViewController!.setupWebView()
      presentViewController(playViewController!, animated: false, completion: nil)
      println("Now we are presenting \(presentedViewController)")
    }
  }
  
}

