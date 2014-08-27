//
//  DialogueViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/29/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import WebKit

class SpriteDialogueViewController: PlayViewChildViewController {
  @IBOutlet weak var dismissButton: UIButton!
  @IBOutlet weak var spriteMessageLabel: UILabel!
  @IBOutlet weak var spriteAvatarImageView: UIImageView!
  @IBOutlet weak var spriteNameLabel: UILabel!
  @IBOutlet weak var continueButton: UIButton!
  let MarkdownParser = NSAttributedStringMarkdownParser()
  var currentDialogue:SpriteDialogue? {
    didSet {
      setSpriteDialogue(currentDialogue!)
      self.view.hidden = false
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addScriptMessageNotificationObservers()
    if currentDialogue != nil {
      self.view.hidden = true
    }
  }
  
  private func addScriptMessageNotificationObservers() {
    WebManager.sharedInstance.scriptMessageNotificationCenter?.addObserver(self,
      selector: Selector("handleDialogue:"),
      name: "spriteSpeechUpdatedHandler",
      object: WebManager.sharedInstance)
  }
  
  func handleDialogue(notification:NSNotification) {
    if let messageBody = notification.userInfo {
      let dialogue = SpriteDialogue(
        image: UIImage(named: "AnyaPortrait"),
        spriteMessage: messageBody["message"]! as String,
        spriteName: messageBody["spriteID"]! as String)
      self.currentDialogue = dialogue
    }
    
  }
  
  func setSpriteDialogue(dialogue:SpriteDialogue) {
    spriteNameLabel.text = dialogue.spriteName
    //Can convert to html http://www.raywenderlich.com/48001/easily-overlooked-new-features-ios-7#textViewLinks
    
    spriteMessageLabel.attributedText =
      MarkdownParser.attributedStringFromMarkdownString(dialogue.spriteMessage)
    spriteAvatarImageView.image = dialogue.image
  }
  
  @IBAction func hitContinueButton(sender: AnyObject?) {
    sendBackboneEvent("level:shift-space-pressed", data: nil)
  }
  
  @IBAction func hitDismissButton(sender: AnyObject?) {
    sendBackboneEvent("level:escape-pressed", data: nil)
    self.view.hidden = true
  }
}
