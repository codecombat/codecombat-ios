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
  var codeBeforeLoad:String?
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
  
  func setupViews() {
    let frameWidth = view.frame.size.width
    let frameHeight = view.frame.size.height
    let aspectRatio = screenshotView.image!.size.width/screenshotView.image!.size.height
    screenshotView.frame = CGRectMake(0, 0, frameWidth, frameWidth / aspectRatio)
    editorContainerView.frame = CGRectMake(0, screenshotView.frame.height, frameWidth, frameHeight)
    editorContainerView.backgroundColor = UIColor.redColor()
    
    setupWebView()
    setupScrollView()
    setupInventory()
    setupEditor()
  }
  
  func setupScrollView() {
    let scrollView = UIScrollView(frame: view.frame)
    scrollView.addSubview(screenshotView)
    if webView != nil {
      scrollView.addSubview(webView!)
    }
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
    
    if codeBeforeLoad != nil {
      textStorage.replaceCharactersInRange(NSMakeRange(0, 0), withAttributedString: NSMutableAttributedString(string: codeBeforeLoad!))
      editorTextView.setNeedsDisplay()
      println("set code before load to \(codeBeforeLoad!)")
    }
  }

  func setupWebView() {
    webView = WebManager.sharedInstance.webView!
    webView!.hidden = false
    webManager.webView = webView
  }
  
  @IBAction func onCast(sender: UIButton) {
    handleTomeSourceRequest()
    WebManager.sharedInstance.publish("tome:manual-cast", event: [:])
  }
  
  func handleTomeSourceRequest(){
    var escapedString = editorTextView.text!.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
    escapedString = escapedString.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
    var js = "if(currentView.tome.spellView) { currentView.tome.spellView.ace.setValue(\"\(escapedString)\"); } else { console.log('damn, no one was selected!'); }"
    println(js)
    WebManager.sharedInstance.evaluateJavaScript(js, completionHandler: nil)
  }
}
