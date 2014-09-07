//
//  LevelLoadingViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/28/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import WebKit

class LevelLoadingViewController: UIViewController {
  
  @IBOutlet weak var backgroundImageView: UIImageView!
  @IBOutlet weak var levelLoadingProgressView: UIProgressView!
  
  var webView: WKWebView?
  let RootURL = WebManager.sharedInstance.rootURL
  let WebViewContextPointer = UnsafeMutablePointer<()>()
  var injectedListeners: Bool = false
  var spriteMessageBeforeUnveil: SpriteDialogue?
  var spellBeforeUnveil: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    instantiateWebView()
    WebManager.sharedInstance.addScriptMessageHandlers()
    addScriptMessageNotificationObservers()
    addWebViewKeyValueObservers()
    loadLevel("mobile-artillery")
    //webView!.hidden = false
    view.addSubview(webView!)
  }
  
  private func addScriptMessageNotificationObservers() {
    let webManager = WebManager.sharedInstance
    webManager.subscribe(self, channel: "level:loading-view-unveiled", selector: Selector("onLevelStarted:"))
    webManager.subscribe(self, channel: "supermodel:load-progress-changed", selector: Selector("onProgressUpdate:"))
    //webManager.subscribe(self, channel: "sprite:speech-updated", selector: Selector("onSpriteSpeechUpdated:"))
    webManager.subscribe(self, channel: "tome:spell-loaded", selector: Selector("onTomeSpellLoaded:"))
    //NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("loginMichael"), name: "allListenersLoaded", object: nil)
  }
  
  deinit {
    WebManager.sharedInstance.unsubscribe(self)
  }
  
  private func instantiateWebView() {
    let WebViewFrame = CGRectMake(0, 0, 1024, 1024 * (589 / 924))  // Full-width Surface, preserving aspect ratio.
    let WebManagerInstance = WebManager.sharedInstance
    webView = WKWebView(frame:WebViewFrame,
      configuration:WebManager.sharedInstance.webViewConfiguration)
    webView!.hidden = true
    WebManagerSharedInstance.webView = webView
  }
  
  private func loadLevel(levelSlug:String) {
    let RequestURL = NSURL(string: "/play/level/\(levelSlug)", relativeToURL: RootURL)
    let Request = NSMutableURLRequest(URL: RequestURL)
    webView!.loadRequest(Request)
  }
  
  func addWebViewKeyValueObservers() {
    webView!.addObserver(self,
      forKeyPath: NSStringFromSelector(Selector("loading")),
      options: nil,
      context: WebViewContextPointer)
    webView!.addObserver(self,
      forKeyPath: NSStringFromSelector(Selector("estimatedProgress")),
      options: NSKeyValueObservingOptions.Initial,
      context: WebViewContextPointer)
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    let DestinationViewController = segue.destinationViewController as NewPlayViewController
    DestinationViewController.webView = webView
    WebManager.sharedInstance.unsubscribe(self)
    if spellBeforeUnveil != nil {
      DestinationViewController.codeBeforeLoad = spellBeforeUnveil
    }
    
    /*
    if spriteMessageBeforeUnveil != nil {
      DestinationViewController.currentSpriteDialogue =
        spriteMessageBeforeUnveil
    }
    */
  }
  
  override func observeValueForKeyPath(
    keyPath: String!,
    ofObject object: AnyObject!,
    change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<()>) {
    if context == WebViewContextPointer {
      switch keyPath! {
      //case NSStringFromSelector(Selector("estimatedProgress")):
        //if webView!.estimatedProgress > 0.8 && !injectedListeners {
        //  injectListeners()
        //}
      default:
        println("\(keyPath) changed")
      }
    } else {
      super.observeValueForKeyPath(keyPath,
        ofObject: object,
        change: change,
        context: context)
    }
  }
  
  func onProgressUpdate(note: NSNotification) {
    if let event = note.userInfo {
      let progress = event["progress"]! as Float
      let progressScalingFactor = 0.8
      let scaledProgress = CGFloat(progress) * CGFloat(progressScalingFactor)
      levelLoadingProgressView.setProgress(Float(scaledProgress), animated: true)
    }
  }
  
  func onLevelStarted(note: NSNotification) {
    performSegueWithIdentifier("levelStartedSegue", sender: self)
  }
  
//  func onSpriteSpeechUpdated(note:NSNotification) {
//    if let event = note.userInfo {
//      println("Setting speech before unveil!")
//      spriteMessageBeforeUnveil  = SpriteDialogue(
//        image: UIImage(named: "AnyaPortrait"),
//        spriteMessage: event["message"]! as String,
//        spriteName: event["spriteID"]! as String)
//    }
//  }
  
  func onTomeSpellLoaded(note:NSNotification) {
    if let event = note.userInfo {
      let spell = event["spell"] as NSDictionary
      spellBeforeUnveil = spell["source"] as? String
      println("got spell before unveil: \(spellBeforeUnveil)")
    }
  }
  
  func loginMichael() {
    let loginScript = "require('/lib/auth').loginUser(" +
      "{'email':'username','password':'password'})"
    webView?.evaluateJavaScript(loginScript,
      completionHandler: { response, error in
          //hasLoggedIn = true
          //isLoggingIn = false
          println("Logged in!")
          //webpageLoadingProgressView.setProgress(0.2, animated: true)
        })
  }
}
