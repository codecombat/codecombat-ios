//
//  TomeInventoryViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/11/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class TomeInventoryViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
  private var inventory: TomeInventory!
  private var inventoryLoaded = false
  var inventoryView: UIScrollView!
  private var draggedView: UIView!
  private var draggedProperty: TomeInventoryItemProperty!
  
  override init() {
//    inventory = TomeInventory(
//      itemsData: parseJSONFile("items_tharin"),
//      propertiesData: parseJSONFile("properties"))
    inventory = TomeInventory()
    super.init(nibName: "", bundle: nil)
  }
  
  required convenience init(coder aDecoder: NSCoder) {
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
    inventoryView.backgroundColor = ColorManager.sharedInstance.inventoryBackground
    view.addSubview(inventoryView)
    
    addScriptMessageNotificationObservers()
  }
  
  func setUpInventory() {
    let subviewsToRemove = inventoryView.subviews as [UIView]
    for var index = subviewsToRemove.count - 1; index >= 0; --index {
      subviewsToRemove[index].removeFromSuperview()
    }
    var itemHeight = 0
    let itemMargin = 10
    for item in inventory.items {
      let width = Int(inventoryView.frame.width) - itemMargin
      let height = Int(inventoryView.frame.height) - itemHeight - itemMargin
      let itemFrame = CGRect(x: itemMargin / 2, y: itemHeight + itemMargin / 2, width: width, height: height)
      let itemView = TomeInventoryItemView(item: item, frame: itemFrame)
      if itemView.showsProperties {
        inventoryView.addSubview(itemView)
        itemHeight += Int(itemView.frame.height) + itemMargin
      }
    }
    inventoryView.contentSize = CGSize(width: inventoryView.frame.width, height: CGFloat(itemHeight))
  }
  
  private func addScriptMessageNotificationObservers() {
    let webManager = WebManager.sharedInstance
    webManager.subscribe(self, channel: "tome:palette-cleared", selector: Selector("onInventoryCleared:"))
    webManager.subscribe(self, channel: "tome:palette-updated", selector: Selector("onInventoryUpdated:"))
  }
  
  func onInventoryCleared(note: NSNotification) {
    //println("inventory cleared: \(note)")
  }
  
  func onInventoryUpdated(note: NSNotification) {
    if inventoryLoaded { return }
    inventoryLoaded = true
    inventory = TomeInventory()
    let userInfo = note.userInfo as [String: AnyObject]
    let entryGroupsJSON = userInfo["entryGroups"] as NSString
    let entryGroups = JSON.parse(entryGroupsJSON)
    var items: [TomeInventoryItem] = []
    for (entryGroupName, entryGroup) in entryGroups.asDictionary! {
      var entries = entryGroup["props"].asArray!
      var entryNames: [String] = entries.map({entry in entry["name"].asString!}) as [String]
      var entryNamesJSON = "\", \"".join(entryNames)
      var imageInfoData = entryGroup["item"].asDictionary!
      var imageURL = imageInfoData["imageURL"]!
      var itemDataJSON = "{\"name\":\"\(entryGroupName)\",\"programmableProperties\":[\"\(entryNamesJSON)\"],\"imageURL\":\"\(imageURL)\"}"
      var itemData = JSON.parse(itemDataJSON)
      var item = TomeInventoryItem(itemData: itemData)
      for entry in entries {
        var property = TomeInventoryItemProperty(propertyData: entry, primary: true)
        item.addProperty(property)
      }
      inventory.addInventoryItem(item)
    }
    setUpInventory()
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool {
    //Make more specific to simultaneous uipangesturerecognizers if other gesture recognizers fire unintentionally
    return true
  }
  
  func handleDrag(recognizer:UIPanGestureRecognizer) {
    if recognizer == inventoryView.panGestureRecognizer {
      return
    }
    let Parent = parentViewController as PlayViewController
    //Change this to reference editor view controller, rather than editor view
    let EditorView = Parent.textViewController.textView
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
      recognizer.enabled = true
      let ItemProperty = ItemView.tomeInventoryItemPropertyAtLocation(recognizer.locationInView(ItemView))
      draggedProperty = ItemProperty
      let DragView = UILabel()
      DragView.font = EditorView.font
      DragView.text = ItemProperty!.codeSnippetForLanguage("python")
      DragView.sizeToFit()
      DragView.center = LocationInParentView
      DragView.backgroundColor = UIColor.clearColor()
      Parent.view.addSubview(DragView)
      draggedView = DragView
      Parent.textViewController.handleItemPropertyDragBegan()
      break
    case .Changed:
      draggedView.center = LocationInParentView
      
      if EditorView.frame.contains(LocationInParentView) {
        var Snippet = draggedProperty.codeSnippetForLanguage("python")
        if Snippet != nil {
          Snippet = draggedProperty.name
        }
        Parent.textViewController.handleItemPropertyDragChangedAtLocation(LocationInEditorContainerView)
      } else {
        Parent.textViewController.textView.currentHighlightingView?.removeFromSuperview()
        Parent.textViewController.textView.currentHighlightingView = nil
      }
      break
    case .Ended:
      draggedView.removeFromSuperview()
      var Snippet = draggedProperty.codeSnippetForLanguage("python")
      if Snippet == nil {
        Snippet = draggedProperty.name
      }
      if EditorView.frame.contains(LocationInParentView) {
        Parent.textViewController.handleItemPropertyDragEndedAtLocation(LocationInEditorContainerView, code: Snippet!)
      } else {
        Parent.textViewController.textView.currentDragHintView?.removeFromSuperview()
        Parent.textViewController.textView.currentDragHintView = nil
        Parent.textViewController.textView.currentHighlightingView?.removeFromSuperview()
        Parent.textViewController.textView.currentHighlightingView = nil
      }
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
