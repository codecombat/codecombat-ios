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
  var playViewController: NewPlayViewController?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    listenToNotifications()
    let mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
    playViewController = mainStoryboard.instantiateViewControllerWithIdentifier("NewPlayViewController") as? NewPlayViewController
    playViewController?.view  // Access this early to get it set up and listening for events.
    loadLevel("opportunism")
  }
  
  private func listenToNotifications() {
    let webManager = WebManager.sharedInstance
    webManager.subscribe(self, channel: "level:loading-view-unveiled", selector: Selector("onLevelStarted:"))
    webManager.subscribe(self, channel: "supermodel:load-progress-changed", selector: Selector("onProgressUpdate:"))
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
  
  func onProgressUpdate(note: NSNotification) {
    if let event = note.userInfo {
      let progress = event["progress"]! as Float
      levelLoadingProgressView.setProgress(progress, animated: true)
    }
  }
  
  //  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
  //    WebManager.sharedInstance.unsubscribe(self)
  //  }
  
  func onLevelStarted(note: NSNotification) {
    presentViewController(playViewController!, animated: true, completion: nil)
    //performSegueWithIdentifier("levelStartedSegue", sender: self)
    //let segue = UIStoryboardSegue(identifier: "levelStartedSegue2", source: self, destination: playViewController!)
    //segue.perform()
    WebManager.sharedInstance.unsubscribe(self)
  }
}
