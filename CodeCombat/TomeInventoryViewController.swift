//
//  TomeInventoryViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/11/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class TomeInventoryViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
  private let inventory:TomeInventory!
  private var inventoryView:UIScrollView!
  private var draggedView:UIView!
  private var draggedProperty:TomeInventoryItemProperty!
  
  override init() {
    inventory = TomeInventory(
      itemsData: parseJSONFile("items_tharin"),
      propertiesData: parseJSONFile("properties"))
    super.init(nibName: "", bundle: nil)
  }
  
  required convenience init(coder aDecoder: NSCoder!) {
    self.init()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let screenBounds = UIScreen.mainScreen().bounds
    let inventoryFrame = CGRect(
      x: 0,
      y: 0,
      width: screenBounds.width / 3,
      height: screenBounds.height)
    inventoryView = UIScrollView(frame: inventoryFrame)
    inventoryView.delegate = self
    
    let DragAndDropRecognizer = UIPanGestureRecognizer(
      target: self,
      action: "handleDrag:")
    DragAndDropRecognizer.delegate = self
    inventoryView.addGestureRecognizer(DragAndDropRecognizer)
    inventoryView.panGestureRecognizer.requireGestureRecognizerToFail(DragAndDropRecognizer)
    
    inventoryView.bounces = false
    inventoryView.backgroundColor = UIColor(
      red: CGFloat(234.0/256.0),
      green: CGFloat(219.0/256.0),
      blue: CGFloat(169.0/256.0),
      alpha: 1)
    // TODO: Calculate the actual size
    inventoryView.contentSize = CGSize(
      width: inventoryFrame.width,
      height: 2 * inventoryFrame.height)
    
    var itemHeight = 0
    let ItemMargin = 10
    for item in inventory.items {
      let Width = Int(inventoryFrame.width) - ItemMargin
      let Height = Int(inventoryFrame.height) - itemHeight - ItemMargin
      let ItemFrame = CGRect(x: ItemMargin/2, y: itemHeight + ItemMargin/2, width: Width, height: Height)
      let ItemView = TomeInventoryItemView(item: item, frame: ItemFrame)
      if ItemView.showsProperties {
        inventoryView.addSubview(ItemView)
        itemHeight += Int(ItemView.frame.height) + ItemMargin
      }
    }
    view.addSubview(inventoryView)
    
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
    //Make more specific to simultaneous uipangesturerecognizers if other gesture recognizers fire unintentionally
    return true
  }
  
  func handleDrag(recognizer:UIPanGestureRecognizer) {
    if recognizer == inventoryView.panGestureRecognizer {
      return
    }
    let Parent = parentViewController as NewPlayViewController
    //Change this to reference editor view controller, rather than editor view
    let EditorView = Parent.editorTextView
    let LocationInParentView = recognizer.locationInView(Parent.view)
    let LocationInEditorContainerView = recognizer.locationInView(Parent.editorContainerView)
    switch recognizer.state {
      
    case .Began:
      //Find the item view which received the click
      var ItemView:TomeInventoryItemView! = itemViewAtLocation(recognizer.locationInView(inventoryView))
      if ItemView == nil || ItemView.tomeInventoryItemPropertyAtLocation(recognizer.locationInView(ItemView)) == nil {
        // This weird code is the way to get the drag and drop recognizer to send
        // failure to the scroll gesture recognizer
        recognizer.enabled = false
        recognizer.enabled = true
        break
      }
      let ItemProperty = ItemView.tomeInventoryItemPropertyAtLocation(recognizer.locationInView(ItemView))
      draggedProperty = ItemProperty
      let DragView = UILabel()
      DragView.font = UIFont(name: "Courier", size: 40)
      DragView.text = ItemProperty!.codeSnippetForLanguage("python")
      DragView.sizeToFit()
      DragView.center = LocationInParentView
      DragView.backgroundColor = UIColor.clearColor()
      Parent.view.addSubview(DragView)
      draggedView = DragView
      break
    case .Changed:
      draggedView.center = LocationInParentView
      
      if EditorView.frame.contains(LocationInParentView) {
        var Snippet = draggedProperty.codeSnippetForLanguage("python")
        if Snippet != nil {
          Snippet = draggedProperty.name
        }
        EditorView.handleItemPropertyDragChangedAtLocation(LocationInEditorContainerView, code: Snippet!)
      }
      break
    case .Ended:
      draggedView.removeFromSuperview()
      var Snippet = draggedProperty.codeSnippetForLanguage("python")
      if Snippet != nil {
        Snippet = draggedProperty.name
      }
      EditorView.handleItemPropertyDragEndedAtLocation(LocationInEditorContainerView, code: Snippet!)
      draggedView = nil
      break
    default:
      break
    }
  }
  
  func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer!) -> Bool {
    if draggedView != nil {
      return false
    }
    if gestureRecognizer != inventoryView.panGestureRecognizer && gestureRecognizer is UIPanGestureRecognizer {
      if itemViewAtLocation(gestureRecognizer.locationInView(inventoryView)) == nil {
        return false
      }
    }
    return true
  }
  
  func itemViewAtLocation(location:CGPoint) -> TomeInventoryItemView! {
    var ItemView:TomeInventoryItemView! = nil
    for subview in inventoryView.subviews {
      if subview is TomeInventoryItemView && subview.frame.contains(location) {
        ItemView = subview as TomeInventoryItemView
      }
    }
    return ItemView
  }
  
  override func loadView() {
    view = UIView(frame: UIScreen.mainScreen().bounds)
  }
  
}
