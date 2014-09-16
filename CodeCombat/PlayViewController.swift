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

  var scrollView: UIScrollView!
  let screenshotView = UIImageView(image: UIImage(named: "largeScreenshot"))
  var webView: WKWebView?
  let editorContainerView = UIView()
  var codeEditor: Editor? = nil
  var editorTextView: EditorTextView!
  var textStorage: EditorTextStorage!
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
    editorContainerView.backgroundColor = UIColor.redColor()
    
    setupScrollView()
    setupInventory()
    setupEditor()
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
    addChildViewController(inventoryViewController)
    editorContainerView.addSubview(inventoryViewController.view)
  }
  
  func setupEditor() {
    textStorage = EditorTextStorage()
    let layoutManager = EditorLayoutManager()
    layoutManager.allowsNonContiguousLayout = true
    textStorage.addLayoutManager(layoutManager)
    let textContainer = NSTextContainer()
    textContainer.lineBreakMode = NSLineBreakMode.ByCharWrapping
    textContainer.widthTracksTextView = true
    layoutManager.addTextContainer(textContainer)
    let editorTextViewFrame = CGRectMake(inventoryFrame.width, 0, editorContainerView.frame.width - inventoryFrame.width, editorContainerView.frame.height)
    editorTextView = EditorTextView(frame: editorTextViewFrame, textContainer: textContainer)
    editorTextView.selectable = true
    editorTextView.editable = true
    
    editorTextView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    
    codeEditor = Editor(textView: editorTextView)
    editorTextView.delegate = codeEditor!
    editorTextView.showLineNumbers()
    editorContainerView.addSubview(editorTextView)
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
        textStorage.replaceCharactersInRange(NSMakeRange(0, 0), withString: startingCode!)
        
        println("set code before load to \(startingCode!)")
      }
      editorTextView.setNeedsDisplay()  // Needed?
    }
  }

  @IBAction func onCast(sender: UIButton) {
    handleTomeSourceRequest()
    webManager.publish("tome:manual-cast", event: [:])
  }
  
  func handleTomeSourceRequest(){
    var escapedString = editorTextView.text!.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
    escapedString = escapedString.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
    var js = "if(currentView.tome.spellView) { currentView.tome.spellView.ace.setValue(\"\(escapedString)\"); } else { console.log('damn, no one was selected!'); }"
    println(js)
    webManager.evaluateJavaScript(js, completionHandler: nil)
  }
}
