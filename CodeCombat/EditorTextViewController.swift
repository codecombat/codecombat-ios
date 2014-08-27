//
//  EditorTextViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/29/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import JavaScriptCore

class EditorTextViewController: PlayViewChildViewController, UITextViewDelegate, UIAlertViewDelegate{
  
  var editorStorage:EditorTextStorage?
  var editorLayoutManager:NSLayoutManager?
  var editorTextContainer:NSTextContainer?
  var editorTextView:UITextView?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let frameXOrigin = CGFloat(0)
    let frameYOrigin = CGFloat(0)
    let frameWidth = self.view.bounds.width
    let frameHeight = CGFloat(self.view.bounds.height - 100)
    let textEditorFrame = CGRectMake(frameXOrigin, frameYOrigin, frameWidth, frameHeight)
    editorStorage = EditorTextStorage()
    editorLayoutManager = EditorLayoutManager()
    editorStorage!.addLayoutManager(editorLayoutManager!)
    editorTextContainer = NSTextContainer()
    editorLayoutManager!.addTextContainer(editorTextContainer!)
    editorTextView = UITextView(frame: textEditorFrame, textContainer: editorTextContainer)
    editorTextView!.delegate = self
    editorStorage!.setEditorTextView(editorTextView!)
    editorTextView!.layer.borderColor = UIColor.redColor().CGColor
    editorTextView!.layer.borderWidth = 3.0
    let linkAttributes = [NSForegroundColorAttributeName: UIColor.redColor()]
    editorTextView!.linkTextAttributes = linkAttributes
    editorTextView!.selectable = true
    editorTextView!.editable = true
    self.view.addSubview(editorTextView!)
    self.view.bringSubviewToFront(editorTextView!)
    addInterfaceNotificationObservers()
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func addScriptMessageNotificationObservers() {
    WebManager.sharedInstance.scriptMessageNotificationCenter?.addObserver(self,
      selector: Selector("handleTomeSpellLoadedNotification:"),
      name: "tomeSpellLoadedHandler",
      object: nil)
    
    WebManager.sharedInstance.scriptMessageNotificationCenter?.addObserver(self, selector: Selector("handleTomeSpellRequest"), name: "tomeSpellRequest", object: nil)
  }
  
  func addInterfaceNotificationObservers() {
    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: Selector("handleInsertTextNotification:"),
      name: "interfaceTextInsertion",
      object: nil)
  }
  
  func handleInsertTextNotification(notification:NSNotification) {
    if let userInfoDictionary = notification.userInfo {
      let TextToInsert = userInfoDictionary["textToInsert"]! as String
      appendString(NSMutableAttributedString(string:TextToInsert))
    }
    
    
    
  }
  
  func setContentsToString(string:NSMutableAttributedString) {
    editorStorage?.beginEditing()
    editorStorage?.appendAttributedString(string)
    editorStorage?.endEditing()
  }
  
  func appendString(string:NSAttributedString) {
    editorStorage?.beginEditing()
    editorStorage?.appendAttributedString(string)
    editorStorage?.endEditing()
  }
  
  private func handleTomeSpellLoadedNotification(notification:NSNotification){
    println("THe spell loaded!!!")
  }
  
  func textView(textView: UITextView!, shouldInteractWithURL URL: NSURL!,
    inRange characterRange: NSRange) -> Bool {
      println("STARTED")
      if URL.scheme == "fillin" {
        println(textView.attributedText.attributedSubstringFromRange(characterRange))
        let alert = UIAlertView(title: "Fill in the condition",
          message: "Please enter the condition",
          delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "OK")
        alert.alertViewStyle = UIAlertViewStyle.PlainTextInput
        alert.show()
        return false
      }
      println(URL.scheme)
      return true
  }
  
  func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
    println("Blah")
  }
  
  @IBAction func cast() {
    handleTomeSourceRequest()
    sendBackboneEvent("tome:manual-cast", data: NSDictionary())
  }
  
  func handleTomeSourceRequest(){
    var escapedString = NSString(string:editorStorage!.string()!.stringByReplacingOccurrencesOfString("\"", withString: "\\\""))
    escapedString = escapedString.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
    webView?.evaluateJavaScript("currentView.tome.spellView.ace.setValue(\"\(escapedString)\");", completionHandler: nil)
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
