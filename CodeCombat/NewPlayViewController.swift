//
//  NewPlayViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class NewPlayViewController: UIViewController, UITextViewDelegate {
  
  let screenshotView = UIImageView(image: UIImage(named: "largeScreenshot"))
  let editorContainerView = UIView()
  var codeEditor:Editor? = nil
  var tomeInventory:TomeInventory? = nil
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
  }
  
  func setupViews() {
    let frameWidth = view.frame.size.width
    let frameHeight = view.frame.size.height
    let aspectRatio = screenshotView.image.size.width/screenshotView.image.size.height
    screenshotView.frame = CGRectMake(0, 0, frameWidth, frameWidth / aspectRatio)
    editorContainerView.frame = CGRectMake(0, screenshotView.frame.height, frameWidth, frameHeight)
    editorContainerView.backgroundColor = UIColor.redColor()
    
    setupScrollView()
    setupInventory()
    setupEditor()
  }
  
  func setupScrollView() {
    let scrollView = UIScrollView(frame: view.frame)
    scrollView.addSubview(screenshotView)
    scrollView.contentSize = CGSizeMake(view.frame.size.width, screenshotView.frame.height + view.frame.size.height)
    scrollView.addSubview(editorContainerView)
    scrollView.bounces = false
    view.addSubview(scrollView)
  }
  
  func setupInventory() {
    let inventoryFrame = CGRectMake(0, 0, editorContainerView.frame.width / 3, editorContainerView.frame.height)
    tomeInventory = TomeInventory(frame: inventoryFrame)
    //Sample items go here
    let testItem = TomeInventoryItem()
    testItem.name = "Programmaticon"
    let testSpell = TomeInventoryItemSpell()
    testSpell.name = "if"
    testSpell.snippet = "if (${0:BLAH){\n\tHi\n}"
    testItem.spells.append(testSpell)
    tomeInventory!.items.append(testItem) //lol NSArray what even is that
    tomeInventory!.setNeedsDisplay()
    editorContainerView.addSubview(tomeInventory!)
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
    let editorTextViewFrame = CGRectMake(tomeInventory!.frame.width, 0, editorContainerView.frame.width - tomeInventory!.frame.width, editorContainerView.frame.height)
    let editorTextView = EditorTextView(frame: editorTextViewFrame, textContainer: textContainer)
    editorTextView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    
    codeEditor = Editor(textView: editorTextView)
    editorTextView.delegate = codeEditor!
    editorTextView.showLineNumbers()
    editorContainerView.addSubview(editorTextView)
  }

}
