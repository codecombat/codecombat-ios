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
    
    var object: AnyObject! = decodeJSONFile("items_tharin")
    println(object)
    //Sample items go here
    /*
    var testItem: [String:AnyObject] = ["name": "Programmaticon", "slot": "programmaticon", "properties": []]
    var prop: [String:AnyObject] = ["name": "if", "type": "snippet", "snippet": "if (${0:BLAH){\n\tHi\n}"]
    var testItemProperties = testItem["properties"] as Array
    testItemProperties.append(prop)
    
    //var testItem = TomeInventoryItem(name: "Programmaticon", slot: "programmaticon")
    //testItem.addProperty(prop)
    tomeInventory!.items.append(testItem)

    testItem = TomeInventoryItem(name: "Holy Sword", slot: "right-hand")
    testItem.addProperty(TomeInventoryItemProperty(name: "attack", type: "function", snippet: "this.attack(${0:this.getNearest(this.getEnemies())})"))
    testItem.addProperty(TomeInventoryItemProperty(name: "target", type: "object", snippet: "this.target"))
    testItem.addProperty(TomeInventoryItemProperty(name: "hasEffect", type: "function", snippet: "this.hasEffect(${0:'power-up'})"))
    testItem.addProperty(TomeInventoryItemProperty(name: "powerUp", type: "function", snippet: "this.powerUp()"))
*/
    
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
