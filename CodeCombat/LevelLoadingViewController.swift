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
  
  var spriteMessageBeforeUnveil: SpriteDialogue?
  var spellBeforeUnveil: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addScriptMessageNotificationObservers()
    loadLevel("opportunism")
    //webView!.hidden = false
    view.addSubview(WebManager.sharedInstance.webView!)
  }
  
  private func addScriptMessageNotificationObservers() {
    let webManager = WebManager.sharedInstance
    webManager.subscribe(self, channel: "level:loading-view-unveiled", selector: Selector("onLevelStarted:"))
    webManager.subscribe(self, channel: "supermodel:load-progress-changed", selector: Selector("onProgressUpdate:"))
    //webManager.subscribe(self, channel: "sprite:speech-updated", selector: Selector("onSpriteSpeechUpdated:"))
    webManager.subscribe(self, channel: "tome:spell-loaded", selector: Selector("onTomeSpellLoaded:"))
  }
  
  deinit {
    WebManager.sharedInstance.unsubscribe(self)
  }
  
  private func loadLevel(levelSlug:String) {
    WebManager.sharedInstance.publish("router:navigate", event: ["route": "/play/level/\(levelSlug)"])
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    let DestinationViewController = segue.destinationViewController as NewPlayViewController
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
  
  func onProgressUpdate(note: NSNotification) {
    if let event = note.userInfo {
      let progress = event["progress"]! as Float
      levelLoadingProgressView.setProgress(progress, animated: true)
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
}
