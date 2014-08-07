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
  var editor:Editor? = nil
  var editorInventory:EditorInventory? = nil
  
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
    editorInventory = EditorInventory(frame: inventoryFrame)
    //Sample items go here
    let testItem = EditorInventoryItem()
    testItem.name = "Programmaticon"
    let testSpell = EditorInventoryItemSpell()
    testSpell.name = "if"
    testSpell.snippet = "if (${0:BLAH){\n\tHi\n}"
    testItem.spells.append(testSpell)
    editorInventory!.items.append(testItem) //lol NSArray what even is that
    editorInventory!.setNeedsDisplay()
    editorContainerView.addSubview(editorInventory!)
  }
  
  func setupEditor() {
    let textStorage = EditorTextStorage()
    let layoutManager = EditorLayoutManager()
    textStorage.addLayoutManager(layoutManager)
    let textContainer = NSTextContainer()
    layoutManager.addTextContainer(textContainer)
    let editorTextViewFrame = CGRectMake(editorInventory!.frame.width, 0, editorContainerView.frame.width - editorInventory!.frame.width, editorContainerView.frame.height)
    let editorTextView = EditorTextView(frame: editorTextViewFrame, textContainer: textContainer)
    editor = Editor(textView: editorTextView)
    editorTextView.delegate = editor!
    editorContainerView.addSubview(editorTextView)
  }

}
