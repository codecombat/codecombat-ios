//
//  NewPlayViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import WebKit

class NewPlayViewController: UIViewController, UITextViewDelegate {
  
  let screenshotView = UIImageView(image: UIImage(named: "largeScreenshot"))
  var webView: WKWebView?
  let editorContainerView = UIView()
  var codeEditor: Editor? = nil
  var editorTextView: EditorTextView!
  var inventoryViewController: TomeInventoryViewController!
  var inventoryFrame: CGRect!
  let webManager = WebManager.sharedInstance
  
  override func viewDidLoad() {
    super.viewDidLoad()
    listenToNotifications()
    setupViews()
  }
  
  func listenToNotifications() {
    // TODO: listen to stuff
  }
  
  deinit {
    WebManager.sharedInstance.unsubscribe(self)
  }
  
  func onEvaluateJavaScript(note:NSNotification) {
    let userInfo:Dictionary<String,String!> = note.userInfo as Dictionary<String,String!>
    self.webView?.evaluateJavaScript(userInfo["js"], completionHandler: nil)
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
    //setupWebView()
  }
  
  func setupScrollView() {
    let scrollView = UIScrollView(frame: view.frame)
    scrollView.addSubview(screenshotView)
    scrollView.contentSize = CGSizeMake(view.frame.size.width, screenshotView.frame.height + view.frame.size.height)
    scrollView.addSubview(editorContainerView)
    scrollView.bounces = false
    scrollView.contentOffset = CGPoint(x: 0, y: 500)  // Helps for testing.
    view.addSubview(scrollView)
  }
  
  func setupInventory() {
    inventoryFrame = CGRectMake(0, 0, editorContainerView.frame.width / 3, editorContainerView.frame.height)
    inventoryViewController = TomeInventoryViewController()
    inventoryViewController.view.frame = inventoryFrame
    addChildViewController(inventoryViewController)
    editorContainerView.addSubview(inventoryViewController.view)
  }
  
  func setupEditor() {
    let textStorage = EditorTextStorage()
    let layoutManager = EditorLayoutManager()
    layoutManager.allowsNonContiguousLayout = true
    textStorage.addLayoutManager(layoutManager)
    let textContainer = NSTextContainer()
    textContainer.lineBreakMode = NSLineBreakMode.ByCharWrapping
    textContainer.widthTracksTextView = true
    layoutManager.addTextContainer(textContainer)
    let editorTextViewFrame = CGRectMake(inventoryFrame.width, 0, editorContainerView.frame.width - inventoryFrame.width, editorContainerView.frame.height)
    editorTextView = EditorTextView(frame: editorTextViewFrame, textContainer: textContainer)
    editorTextView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    
    codeEditor = Editor(textView: editorTextView)
    editorTextView.delegate = codeEditor!
    editorTextView.showLineNumbers()
    editorContainerView.addSubview(editorTextView)
  }

  func setupWebView() {
    let webViewFrame = CGRectMake(0, 0, 563 , 359)
    webView!.hidden = false
    self.view.addSubview(webView!)
    webManager.webView = webView
  }
}
