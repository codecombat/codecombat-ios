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
    
    let inventoryFrame = CGRectMake(0, 0, editorContainerView.frame.width / 3, editorContainerView.frame.height)
    let inventory = EditorInventory(frame: inventoryFrame)
    //Sample items go here
    let testItem = EditorInventoryItem()
    testItem.name = "Programmaticon"
    let testSpell = EditorInventoryItemSpell()
    testSpell.name = "if"
    testSpell.snippet = "if (${0:BLAH){\n\tHi\n}"
    testItem.spells.append(testSpell)
    inventory.items.append(testItem) //lol NSArray what even is that
    inventory.setNeedsDisplay()
    editorContainerView.addSubview(inventory)
    
    let textStorage = EditorTextStorage()
    let layoutManager = EditorLayoutManager()
    textStorage.addLayoutManager(layoutManager)
    let textContainer = NSTextContainer()
    layoutManager.addTextContainer(textContainer)
    let editorTextViewFrame = CGRectMake(inventoryFrame.width, 0, editorContainerView.frame.width - inventoryFrame.width, editorContainerView.frame.height)
    let editorTextView = EditorTextView(frame: editorTextViewFrame, textContainer: textContainer)
    editorTextView.delegate = self
    
    editorContainerView.addSubview(editorTextView)
    
    let scrollView = UIScrollView(frame: view.frame)
    scrollView.addSubview(screenshotView)
    scrollView.contentSize = CGSizeMake(frameWidth, screenshotView.frame.height + frameHeight)
    scrollView.addSubview(editorContainerView)
    scrollView.bounces = false
    view.addSubview(scrollView)
  }
  
  func textViewDidChange(textView: UITextView!) {
    textView.setNeedsDisplay()
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  /*
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
  // Get the new view controller using segue.destinationViewController.
  // Pass the selected object to the new view controller.
  }
  */
  
}
