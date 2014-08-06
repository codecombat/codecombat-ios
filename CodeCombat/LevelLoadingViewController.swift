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
  var spellBeforeUnveil:String?
  
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
    let WebManagerInstance = WebManager.sharedInstance
    struct ScriptMessageObserver {
      var selector:Selector = Selector()
      var handlerName = ""
    }
    
    let scriptMessageObservers = [
      ScriptMessageObserver(
        selector: Selector("handleProgressUpdate:"),
        handlerName: "supermodelUpdateProgressHandler"),
      ScriptMessageObserver(
        selector: Selector("handleLevelStarted"),
        handlerName: "levelStartedHandler"),
      ScriptMessageObserver(
        selector: Selector("handleDialogue:"),
        handlerName: "spriteSpeechUpdatedHandler"),
      ScriptMessageObserver(
        selector: Selector("handleTomeSpellLoaded:"),
        handlerName: "tomeSpellLoadedHandler")
    ]
    for observer in scriptMessageObservers {
      WebManagerInstance.scriptMessageNotificationCenter?.addObserver(self,
        selector: observer.selector,
        name: observer.handlerName,
        object: WebManager.sharedInstance)
    }
    //NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("loginMichael"), name: "allListenersLoaded", object: nil)
  }
  
   private func instantiateWebView() {
    let WebViewFrame = CGRectMake(0, 0, 563 , 359)
    let WebManagerInstance = WebManager.sharedInstance
    webView = WKWebView(frame:WebViewFrame,
      configuration:WebManager.sharedInstance.webViewConfiguration)
  }
  
  private func loadLevel(levelSlug:String) {
    let RequestURL = NSURL(string: "/play/level/\(levelSlug)",
      relativeToURL: RootURL)
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
  
  override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
    let DestinationViewController =
      segue.destinationViewController as PlayViewController
    DestinationViewController.webView = webView
    let nc = WebManager.sharedInstance.scriptMessageNotificationCenter!
    nc.removeObserver(self)
    
    if spriteMessageBeforeUnveil != nil {
      DestinationViewController.currentSpriteDialogue =
        spriteMessageBeforeUnveil
    }
    if spellBeforeUnveil != nil {
      DestinationViewController.spellBeforeLoad = spellBeforeUnveil
    }
  }
  
  override func observeValueForKeyPath(
    keyPath: String!,
    ofObject object: AnyObject!,
    change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<()>) {
    if context == WebViewContextPointer {
      switch keyPath! {
      case NSStringFromSelector(Selector("estimatedProgress")):
        if webView!.estimatedProgress > 0.8 && !injectedListeners {
          injectListeners()
        }
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
  
  func handleProgressUpdate(notification:NSNotification) {
    let UserInfoDictionary = notification.userInfo as NSDictionary
    let Progress = UserInfoDictionary["progress"] as Float
    let ProgressScalingFactor = 0.8
    let scaledProgress = CGFloat(Progress) * CGFloat(ProgressScalingFactor)
    println("Progress updated")
    levelLoadingProgressView.setProgress(Float(scaledProgress), animated: true)
  }
  
  func handleLevelStarted() {
    println("Level started!")
    performSegueWithIdentifier("levelStartedSegue", sender: self)
  }
  
  func handleDialogue(notification:NSNotification) {
    let messageBody = notification.userInfo as NSDictionary
    println("Setting speech before unveil!")
    spriteMessageBeforeUnveil  = SpriteDialogue(
      image: UIImage(named: "AnyaPortrait"),
      spriteMessage: messageBody["message"] as String,
      spriteName: messageBody["spriteID"] as String)
  }
  func handleTomeSpellLoaded(notification:NSNotification) {
    let messageBody = notification.userInfo as NSDictionary
    spellBeforeUnveil = messageBody["spellSource"] as? String
  }
  
  func injectListeners() {
    injectedListeners = true
    //injectProgressListener()
    WebManager.sharedInstance.injectBackboneListeners(webView!)
    //loginMichael()
  }
  
  func injectProgressListener() {
    var error:NSError? = nil
    let scriptFilePath = NSBundle.mainBundle()
      .pathForResource("progressListener", ofType: "js")
    let scriptFromFile = NSString.stringWithContentsOfFile(scriptFilePath,
      encoding: NSUTF8StringEncoding,
      error: &error)
    
    webView?.evaluateJavaScript(scriptFromFile,
      completionHandler: { response, error in
        if error != nil {
          println("There was an error injecting the progress listener:\(error)")
        } else {
          println("Injected the progress listener!")
        }
      })
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
