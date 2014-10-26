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
  var webManager = WebManagerSharedInstance
  var webView: WKWebView = WebManagerSharedInstance.webView!
//  override var view: UIView {
//    get { return webView as UIView }
//    set { webView = newValue as WKWebView }
//  }
  var playViewController: PlayViewController?
  
//  override func loadView() {
//    view = WebManagerSharedInstance.webView!
//  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    webView = WebManagerSharedInstance.webView!
    view.addSubview(webView)
    //delay(5) {
    //  self.listenToNotifications()
    //}
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("listenToNotifications"), name: "webViewDidFinishNavigation", object: nil)
  }
  
  func listenToNotifications() {
    delay(1, {
      self.webManager.subscribe(self, channel: "router:navigated", selector: Selector("onNavigated:"))
      self.webManager.subscribe(self, channel: "level:loading-view-unveiled", selector: Selector("onLevelStarted:"))
      //webManager.subscribe(self, channel: "supermodel:load-progress-changed", selector: Selector("onProgressUpdate:"))
    })
    
  }
  
  deinit {
    WebManager.sharedInstance.unsubscribe(self)
  }
  
  private func loadLevel(levelSlug:String) {
    WebManager.sharedInstance.publish("router:navigate", event: ["route": "/play/level/\(levelSlug)"])
  }
  
  private func loadWorldMap() {
    WebManager.sharedInstance.publish("router:navigate", event: ["route": "/play"])
  }
  
  private func isRouteLevel(route: String) -> Bool {
    return route.rangeOfString("/play/level/", options: NSStringCompareOptions.LiteralSearch) != nil
  }
  
  private func updateFrame(route: String) {
    var webViewFrame = CGRectMake(0, 0, 1024, 768)  // Full-size
    if isRouteLevel(route) {
      webViewFrame = CGRectMake(0, 0, 1024, 1024 * (589 / 924))  // Full-width Surface, preserving aspect ratio.
    }
    WebManager.sharedInstance.webView!.frame = webViewFrame
  }
  
  private func adjustPlayView(route: String) {
    if isRouteLevel(route) {
      let mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
      playViewController = mainStoryboard.instantiateViewControllerWithIdentifier("PlayViewController") as? PlayViewController
      playViewController?.view  // Access this early to get it set up and listening for events.
      println("Created a playViewController for \(route)")
    }
    else {
      println("Route is not a level \(route), so dismissing playViewController \(playViewController), have presentedViewController \(presentedViewController)")
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
  
  //  func onProgressUpdate(note: NSNotification) {
  //    if let event = note.userInfo {
  //      let progress = event["progress"]! as Float
  //      levelLoadingProgressView.setProgress(progress, animated: true)
  //    }
  //  }
  
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

