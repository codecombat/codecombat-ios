//
//  WebManager.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/26/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import WebKit
class WebManager: NSObject, WKScriptMessageHandler {
  
  var webViewConfiguration:WKWebViewConfiguration!
  var urlSesssionConfiguration:NSURLSessionConfiguration?
  let rootURL = NSURL(scheme: "http", host: "10.0.1.9:3000", path: "/")
  var operationQueue:NSOperationQueue?
  var listenersInjectedSoFar = 0
  
  var scriptMessageNotificationCenter:NSNotificationCenter!
  class var sharedInstance:WebManager {
    return WebManagerSharedInstance
  }
  
  struct listenerData {
    var additionalJS = ""
    var javascriptMessageFormat = ""
    var backboneEvent = ""
    var scriptMessageHandlerName = ""
  }
  
  let BackboneListeners = [
    listenerData(
      additionalJS: "",
      javascriptMessageFormat: "{}",
      backboneEvent: "level:loading-view-unveiled",
      scriptMessageHandlerName: "levelStartedHandler"),
    listenerData(
      additionalJS: "if (!e.message) return; ",
      javascriptMessageFormat: "{'spriteID':e.sprite.thang.id," +
        "'message':e.message}",
      backboneEvent: "sprite:speech-updated",
      scriptMessageHandlerName: "spriteSpeechUpdatedHandler"),
    listenerData(
      additionalJS: "",
      javascriptMessageFormat: "{'frame':e.frame,'frameRate':" +
        "e.world.frameRate,'totalFrames':e.world.totalFrames}",
      backboneEvent: "surface:frame-changed",
      scriptMessageHandlerName: "surfaceFrameChangedHandler"),
    listenerData(
      additionalJS: "",
      javascriptMessageFormat: "{'spellSource':e.spell.source}",
      backboneEvent: "tome:spell-loaded",
      scriptMessageHandlerName: "tomeSpellLoadedHandler"),
    listenerData(
      additionalJS: "",
      javascriptMessageFormat:"{'propGroups':e.propGroups,'allDocs':e.allDocs}",
      backboneEvent: "tome:update-snippets",
      scriptMessageHandlerName: "tomeUpdateSnippetsHandler"),
    listenerData(
      additionalJS: "",
      javascriptMessageFormat: "{}",
      backboneEvent: "tome:source-request",
      scriptMessageHandlerName: "tomeSourceRequestHandler"),
    listenerData(
      additionalJS: "",
      javascriptMessageFormat: "{'progress':e}",
      backboneEvent: "supermodel:update-progress",
      scriptMessageHandlerName: "supermodelUpdateProgressHandler"
    )
  ]
  
  override init() {
    super.init()
    operationQueue = NSOperationQueue()
    webViewConfiguration = WKWebViewConfiguration()
    scriptMessageNotificationCenter = NSNotificationCenter()
    
  }
  
  func userContentController(userContentController: WKUserContentController!,
    didReceiveScriptMessage message: WKScriptMessage!) {
    scriptMessageNotificationCenter.postNotificationName(message.name,
      object: self, userInfo: message.body as? NSDictionary)
  }
  
  func addScriptMessageHandlers() {
    let contentController = self.webViewConfiguration!.userContentController
    for listener in BackboneListeners {
      contentController.addScriptMessageHandler(self,
        name: listener.scriptMessageHandlerName)
    }
    //contentController.addScriptMessageHandler(self, name: "progressHandler")
  }
  
  func injectBackboneListeners(webView:WKWebView!) {
    for listener in BackboneListeners {
      injectBackboneListenerIntoWebView(webView,
        additionalJS: listener.additionalJS,
        javascriptMessageFormat: listener.javascriptMessageFormat,
        backboneEvent: listener.backboneEvent,
        scriptMessageHandlerName: listener.scriptMessageHandlerName)
    }
  }
  
  func injectBackboneListenerIntoWebView(webView:WKWebView!,
    additionalJS:String, javascriptMessageFormat:String,
    backboneEvent:String, scriptMessageHandlerName:String ) {
      let script =
      "Backbone.Mediator.subscribe('\(backboneEvent)'," +
        "function(e){ \(additionalJS) try " +
        "{webkit.messageHandlers.\(scriptMessageHandlerName)" +
      ".postMessage(\(javascriptMessageFormat));} catch (err) {throw(err)}});"
      println("Injecting the \(scriptMessageHandlerName)")
      webView.evaluateJavaScript(script,
        completionHandler: backboneInjectionCompletionHandler)
  }
  
  func backboneInjectionCompletionHandler(response:AnyObject!, error:NSError?) {
    if error != nil {
      println("There was an error injecting the progress listener: \(error)")
    }
    listenersInjectedSoFar += 1
    if listenersInjectedSoFar == BackboneListeners.count {
      println("All have been injected!")
      NSNotificationCenter.defaultCenter().postNotificationName("allListenersLoaded", object: self)
    }
  }

}
let WebManagerSharedInstance = WebManager()
