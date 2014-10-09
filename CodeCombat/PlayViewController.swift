//
//  PlayViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import WebKit

class PlayViewController: UIViewController, UITextViewDelegate {

  @IBOutlet weak var redoButton: UIButton!
  @IBOutlet weak var undoButton: UIButton!
  
  var scrollView: UIScrollView!
  let screenshotView = UIImageView(image: UIImage(named: "largeScreenshot"))
  var webView: WKWebView?
  let editorContainerView = UIView()
  var textViewController: EditorTextViewController!
  var inventoryViewController: TomeInventoryViewController!
  var inventoryFrame: CGRect!
  let webManager = WebManager.sharedInstance
  
  override func viewDidLoad() {
    super.viewDidLoad()
    listenToNotifications()
    setupViews()
  }
  
  private func listenToNotifications() {
    webManager.subscribe(self, channel: "sprite:speech-updated", selector: Selector("onSpriteSpeechUpdated:"))
    webManager.subscribe(self, channel: "tome:spell-loaded", selector: Selector("onTomeSpellLoaded:"))
    let nc = NSNotificationCenter.defaultCenter()
    nc.addObserver(self, selector: Selector("setUndoRedoEnabled"), name: "textEdited", object: nil)
  }
  
  deinit {
    WebManager.sharedInstance.unsubscribe(self)
  }
  
  func setupViews() {
    let frameWidth = view.frame.size.width
    let frameHeight = view.frame.size.height
    let aspectRatio = screenshotView.image!.size.width/screenshotView.image!.size.height
    screenshotView.frame = CGRectMake(0, 0, frameWidth, frameWidth / aspectRatio)
    editorContainerView.frame = CGRectMake(0, screenshotView.frame.height, frameWidth, frameHeight)
    setupScrollView()
    setupInventory()
    setupEditor()
    textViewController.textStorage.undoManager.removeAllActions()
    setUndoRedoEnabled()
  }
  
  func setupScrollView() {
    scrollView = UIScrollView(frame: view.frame)
    scrollView.addSubview(screenshotView)
    scrollView.contentSize = CGSizeMake(view.frame.size.width, screenshotView.frame.height + view.frame.size.height)
    scrollView.addSubview(editorContainerView)
    scrollView.bounces = false
    scrollView.contentOffset = CGPoint(x: 0, y: 200)  // Helps for testing.
    view.insertSubview(scrollView, atIndex: 0)
  }
  
  func setupInventory() {
    inventoryFrame = CGRectMake(0, 0, editorContainerView.frame.width / 3, editorContainerView.frame.height)
    inventoryViewController = TomeInventoryViewController()
    inventoryViewController.view.frame = inventoryFrame
    //helps to fix a scrolling bug
    scrollView.panGestureRecognizer.requireGestureRecognizerToFail(inventoryViewController.inventoryView.panGestureRecognizer)
    addChildViewController(inventoryViewController)
    editorContainerView.addSubview(inventoryViewController.view)
  }
  
  func setupEditor() {
    let editorTextViewFrame = CGRectMake(inventoryFrame.width, 0, editorContainerView.frame.width - inventoryFrame.width, editorContainerView.frame.height)
    textViewController = EditorTextViewController()
    textViewController.view.frame = editorTextViewFrame
    
    textViewController.createTextViewWithFrame(editorTextViewFrame)
    scrollView.panGestureRecognizer.requireGestureRecognizerToFail(textViewController.dragGestureRecognizer)
    addChildViewController(textViewController)
    editorContainerView.addSubview(textViewController.textView)
  }

  func setupWebView() {
    webView = webManager.webView!
    webView!.hidden = false
    if webView != nil {
      scrollView.addSubview(webView!)
    }
  }

  func onSpriteSpeechUpdated(note:NSNotification) {
//    if let event = note.userInfo {
//      println("Setting speech before unveil!")
//      spriteMessageBeforeUnveil  = SpriteDialogue(
//        image: UIImage(named: "AnyaPortrait"),
//        spriteMessage: event["message"]! as String,
//        spriteName: event["spriteID"]! as String)
//    }
  }
  
  func onTomeSpellLoaded(note:NSNotification) {
    if let event = note.userInfo {
      let spell = event["spell"] as NSDictionary
      let startingCode = spell["source"] as? String
      if startingCode != nil {
        textViewController.replaceTextViewContentsWithString(startingCode!)
        textViewController.textStorage.undoManager.removeAllActions()
        println("set code before load to \(startingCode!)")
      }
    }
  }

  @IBAction func onCodeRun(sender: UIButton) {
    handleTomeSourceRequest()
    webManager.publish("tome:manual-cast", event: [:])
    scrollView.contentOffset = CGPoint(x: 0, y: 0)
  }

  @IBAction func onCodeSubmitted(sender: UIButton) {
    handleTomeSourceRequest()
    webManager.publish("tome:manual-cast", event: ["realTime": true])
    scrollView.contentOffset = CGPoint(x: 0, y: 0)
  }
  
  @IBAction func onUndo(sender:UIButton) {
    textViewController.textStorage.undoManager.undo()
    textViewController.textView.setNeedsDisplay()
  }
  
  @IBAction func onRedo(sender:UIButton) {
    println("Should redo")
    textViewController.textStorage.undoManager.redo()
    textViewController.textView.setNeedsDisplay()
  }
  
  func setUndoRedoEnabled() {
    println("Setting undo redo enabled")
    undoButton.enabled = textViewController.textStorage.undoManager.canUndo
    redoButton.enabled = textViewController.textStorage.undoManager.canRedo
  }

  func handleTomeSourceRequest(){
    var escapedString = textViewController.textView.text!.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
    escapedString = escapedString.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
    var js = "if(currentView.tome.spellView) { currentView.tome.spellView.ace.setValue(\"\(escapedString)\"); } else { console.log('damn, no one was selected!'); }"
    //println(js)
    webManager.evaluateJavaScript(js, completionHandler: nil)
  }
}
