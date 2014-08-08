//
//  TomeInventory.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/6/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import QuartzCore

class TomeInventoryView: UIScrollView, UIGestureRecognizerDelegate {
  
  var items: [TomeInventoryItem] = []
  var itemHeight: CGFloat = CGFloat(0.0)
  var currentDragRecognizer:UIPanGestureRecognizer? = nil
  var currentDraggedItemProperty:TomeInventoryItemProperty? = nil
  var dragAndDropRecognizer:UIPanGestureRecognizer? = nil
  var draggedView:UIView? = nil
  var editorView:EditorTextView? = nil

  func baseInit() {
    bounces = false
    backgroundColor = UIColor.blueColor()
    let width = frame.width
    let height = 2 * frame.height
    contentSize = CGSizeMake(width, height)
    backgroundColor = UIColor(red: CGFloat(234.0/256.0), green: CGFloat(219.0/256.0), blue: CGFloat(169.0/256.0), alpha: 1)
    setupGestureRecognizer()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    baseInit()
  }
  
  required init(coder aDecoder: NSCoder!) {
    super.init(coder: aDecoder)
    baseInit()
  }
  
  func addItem(item: TomeInventoryItem) {
    let Margin = CGFloat(5.0)
    let itemFrame = CGRect(x: Margin, y: itemHeight + Margin, width: self.frame.width - 2 * Margin, height: self.frame.height - itemHeight - 2 * Margin)
    let itemView = TomeInventoryItemView(item: item, frame: itemFrame)
    if itemView.showsProperties {
      addSubview(itemView)
      itemHeight += itemView.frame.height + 2 * Margin
    }
    items.append(item)
  }
  
  func setupGestureRecognizer() {
    dragAndDropRecognizer = UIPanGestureRecognizer(target: self, action: "handleDrag:")
    addGestureRecognizer(dragAndDropRecognizer!)
    panGestureRecognizer.requireGestureRecognizerToFail(dragAndDropRecognizer!)
  }
  
  func handleDrag(recognizer:UIPanGestureRecognizer) {
    var itemView:TomeInventoryItemView? = nil
    if editorView == nil {
      let SuperView = superview!
      for subview in SuperView.subviews {
        if subview.isKindOfClass(EditorTextView) {
          editorView = subview as? EditorTextView
          break
        }
      }
    }
    switch recognizer.state {
    case .Began:
      if currentDragRecognizer != nil {
        return
      }
      let Item = tomeInventoryItemPropertyAtLocationWithRecognizer(recognizer)
      if Item == nil {
        recognizer.enabled = false
        recognizer.enabled = true
      } else {
        currentDragRecognizer = recognizer
        currentDraggedItemProperty = Item
        //Try basic drag
        let SuperViewLocation = recognizer.locationInView(superview)
        let TestViewFrame = CGRectMake(0, 0, 50, 50)
        let TestView = UILabel(frame: TestViewFrame)
        TestView.font = UIFont(name: "Courier", size: 40)
        let Snippet = Item!.propertyData["snippets"]["python"]["code"]
        if Snippet.isString {
          TestView.text = Snippet.toString(pretty: true)
        } else {
          TestView.text = Item!.propertyData["name"].toString(pretty: false)
        }
        TestView.sizeToFit()
        TestView.center = SuperViewLocation
        TestView.backgroundColor = UIColor.clearColor()
        superview?.addSubview(TestView)
        draggedView = TestView
      }
      
      break
    case .Ended:
      //TODO: Check if this is necessary
      if recognizer != currentDragRecognizer {
        return
      }
      if editorView!.frame.contains(recognizer.locationInView(superview)) {
        println(currentDraggedItemProperty!.propertyData["name"])
      }
      draggedView?.removeFromSuperview()
      editorView!.handleItemPropertyDragEndedAtLocation(recognizer.locationInView(editorView), code: getSnippetForItemProperty(currentDraggedItemProperty!))
      draggedView = nil
      currentDragRecognizer = nil
      break
    case .Changed:
      let Center = recognizer.locationInView(superview)
      draggedView?.center = Center
      if editorView!.frame.contains(recognizer.locationInView(superview)) {
        editorView!.handleItemPropertyDragChangedAtLocation(recognizer.locationInView(editorView), code: getSnippetForItemProperty(currentDraggedItemProperty!))
      }
      break
    default:
      break
    }
  }
  
  func getSnippetForItemProperty(itemProperty:TomeInventoryItemProperty) -> String {
    let Snippet = itemProperty.propertyData["snippets"]["python"]["code"]
    if Snippet.isString {
      return Snippet.toString(pretty: false) + "\n"
    } else {
      return itemProperty.propertyData["name"].toString(pretty: false) + "\n"
    }
  }
  
  func tomeInventoryItemPropertyAtLocationWithRecognizer(recognizer:UIPanGestureRecognizer) -> TomeInventoryItemProperty? {
    for subview in subviews {
      if !subview.isKindOfClass(TomeInventoryItemView) {
        continue
      }
      let CandidateView = subview as TomeInventoryItemView
      if CandidateView.frame.contains(recognizer.locationInView(self)) {
        return CandidateView.tomeInventoryItemPropertyAtLocation(recognizer.locationInView(CandidateView))
      }
    }
    return nil
  }
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
    if gestureRecognizer == panGestureRecognizer && otherGestureRecognizer == dragAndDropRecognizer ||
      otherGestureRecognizer == panGestureRecognizer && gestureRecognizer == dragAndDropRecognizer {
        return true
    }
    return false
  }
  
}
