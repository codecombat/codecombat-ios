//
//  PlayViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/27/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import WebKit
import SpriteKit

class PlayViewController: UIViewController {
  @IBOutlet weak var webViewContainer: UIView!
  @IBOutlet weak var escapeButton: UIButton!
  @IBOutlet weak var webpageLoadingProgressView: UIProgressView!
  var spriteDialogueView: SpriteDialogueViewController!
  var levelPlaybackView: LevelPlaybackViewController!
  var editorView:EditorTextViewController!
  var equippedItemsView:EquippedItemsViewController!
  var webView: WKWebView?
  var currentSpriteDialogue:SpriteDialogue?
  var spellBeforeLoad:String?
  var interfaceNotificationCenter:NSNotificationCenter?
  
  required init(coder aDecoder: NSCoder)  {
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    interfaceNotificationCenter = NSNotificationCenter()
    let webViewFrame = CGRectMake(0, 0, 563 , 359)
    webView!.hidden = false
    self.view.addSubview(webView!)
    discoverAndSetChildViewControllers()
    
    if currentSpriteDialogue != nil {
      spriteDialogueView!.currentDialogue = currentSpriteDialogue
    }
    if spellBeforeLoad != nil {
      editorView.setContentsToString(NSMutableAttributedString(string:spellBeforeLoad!))
    }
  }
  
  func discoverAndSetChildViewControllers() {
    for childViewController in self.childViewControllers {
      if childViewController.isKindOfClass(SpriteDialogueViewController) {
        self.spriteDialogueView =
          childViewController as? SpriteDialogueViewController
        spriteDialogueView!.webView = webView
      } else if childViewController.isKindOfClass(LevelPlaybackViewController) {
        levelPlaybackView =
          childViewController as? LevelPlaybackViewController
        levelPlaybackView!.webView = webView
        levelPlaybackView!.notificationCenter = interfaceNotificationCenter
      } else if childViewController.isKindOfClass(EditorTextViewController) {
        editorView =
          childViewController as? EditorTextViewController
        editorView!.notificationCenter = interfaceNotificationCenter
        editorView!.webView = webView
      } else if childViewController.isKindOfClass(EquippedItemsViewController) {
        equippedItemsView =
          childViewController as? EquippedItemsViewController
        equippedItemsView!.notificationCenter = interfaceNotificationCenter
      }
    }
  }

}
