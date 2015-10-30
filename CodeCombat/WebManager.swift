//
//  WebManager.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/26/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import WebKit
class WebManager: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
  
	var webViewConfiguration: WKWebViewConfiguration!
	var urlSesssionConfiguration: NSURLSessionConfiguration?
	let allowedRoutePrefixes = ["http://localhost:3000", "https://codecombat.com"]
	var operationQueue: NSOperationQueue?
	var webView: WKWebView?  // Assign this if we create one, so that we can evaluate JS in its context.
	var lastJSEvaluated: String?
	var scriptMessageNotificationCenter: NSNotificationCenter!
	var activeSubscriptions = [String: Int]()
	var activeObservers = [NSObject : [String]]()

	var hostReachibility:Reachability!
	var authCookieIsFresh:Bool = false
	var webKitCheckupTimer: NSTimer?
	var webKitCheckupsMissed: Int = -1
	var currentFragment: String?
	var afterLoginFragment: String?

  class var sharedInstance:WebManager {
    return WebManagerSharedInstance
  }
  
  func checkReachibility() {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reachibilityChanged:"), name: kReachabilityChangedNotification, object: nil)
    hostReachibility = Reachability(hostName: "codecombat.com")
    hostReachibility.startNotifier()
  }
  
  func reachibilityChanged(note:NSNotification) {
    if hostReachibility.currentReachabilityStatus().rawValue == NotReachable.rawValue {
      print("Host unreachable")
      NSNotificationCenter.defaultCenter().postNotificationName("websiteNotReachable", object: nil)
    } else {
      print("Host reachable!")
      NSNotificationCenter.defaultCenter().postNotificationName("websiteReachable", object: nil)
    }
  }

  override init() {
    super.init()
    operationQueue = NSOperationQueue()
    scriptMessageNotificationCenter = NSNotificationCenter()
    instantiateWebView()
    subscribe(self, channel: "application:error", selector: "onJSError:")
    subscribe(self, channel: "router:navigated", selector: Selector("onNavigated:"))
    webKitCheckupTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("checkWebKit"), userInfo: nil, repeats: true)
  }
  
  private func instantiateWebView() {
    let WebViewFrame = CGRectMake(0, 0, 1024, 768)  // Full-size
    webViewConfiguration = WKWebViewConfiguration()
    addScriptMessageHandlers()
    webView = WKWebView(frame: WebViewFrame, configuration: webViewConfiguration)
    webView!.navigationDelegate = self
//    if let email = User.currentUser?.email, password = User.currentUser?.password {
//      logIn(email: email, password: password)
//    }
  }
  
  func removeAllUserScripts() {
    webViewConfiguration!.userContentController.removeAllUserScripts()
  }
  
  func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
    print("Comitted navigation to \(webView.URL)")
    if !routeURLHasAllowedPrefix(webView.URL!.absoluteString) {
      webView.stopLoading()
      webView.loadRequest(NSURLRequest(URL: NSURL(string: "/play", relativeToURL: rootURL)!))
    } else {
      //Inject the no-zoom javascript
      let noZoomJS = "var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);"
      webView.evaluateJavaScript(noZoomJS, completionHandler: nil)
      print("webView didCommitNavigation")
    }
    currentFragment = self.webView!.URL!.path!
  }
  
  func routeURLHasAllowedPrefix(route:String) -> Bool {
    for allowedPrefix in allowedRoutePrefixes {
      if route.hasPrefix(allowedPrefix) {
        return true
      }
    }
    return false
  }

  func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    NSNotificationCenter.defaultCenter().postNotificationName("webViewDidFinishNavigation", object: nil)
    print("webView didFinishNavigation")
    for (channel, count) in activeSubscriptions {
      if count > 0 {
        print("Reregistering \(channel)")
        registerSubscription(channel)
      }
    }
    if afterLoginFragment != nil {
      print("Now that we have logged in, we are navigating to \(afterLoginFragment!)")
      publish("router:navigate", event: ["route": afterLoginFragment!])
      afterLoginFragment = nil
    }
  }
  
  //requires that User.email and User.password are set
  func createAnonymousUser() {
	guard let username = User.currentUser?.username, password = User.currentUser?.password else { return }
    //should include something
    let creationScript = "function makeAnonymousUser() { me.set('iosIdentifierForVendor','\(username)'); me.set('password','\(password)'); me.save();} if (!me.get('iosIdentifierForVendor') && me.get('anonymous')) setTimeout(makeAnonymousUser,1);"
    print("Injecting script \(creationScript)")
    let userScript = WKUserScript(source: creationScript, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
    webViewConfiguration!.userContentController.addUserScript(userScript)
    let requestURL = NSURL(string: "/play", relativeToURL: rootURL)
    let request = NSMutableURLRequest(URL: requestURL!)
    webView!.loadRequest(request)
  }
  
  func subscribe(observer: AnyObject, channel: String, selector: Selector) {
    scriptMessageNotificationCenter.addObserver(observer, selector: selector, name: channel, object: self)
    if activeSubscriptions[channel] == nil {
      activeSubscriptions[channel] = 0
    }
    activeSubscriptions[channel] = activeSubscriptions[channel]! + 1
    if activeObservers[observer as! NSObject] == nil {
      activeObservers[observer as! NSObject] = []
    }
    activeObservers[observer as! NSObject]!.append(channel)
    if activeSubscriptions[channel] == 1 {
      registerSubscription(channel)
    }
    //println("Subscribed \(observer) to \(channel) so now have activeSubscriptions \(activeSubscriptions) activeObservers \(activeObservers)")
  }
  
  private func registerSubscription(channel: String) {
    evaluateJavaScript([
      "window.addIPadSubscriptionIfReady = function(channel) {",
      "  if (window.addIPadSubscription) {",
      "    window.addIPadSubscription(channel);",
      "    console.log('Totally subscribed to', channel);",
      "  }",
      "  else {",
      "    console.log('Could not add iPad subscription', channel, 'yet.')",
      "    setTimeout(function() { window.addIPadSubcriptionIfReady(channel); }, 500);",
      "  }",
      "}",
      "window.addIPadSubscriptionIfReady('\(channel)');"
      ].joinWithSeparator("\n"), completionHandler: nil)
  }
  
  func unsubscribe(observer: AnyObject) {
    scriptMessageNotificationCenter.removeObserver(observer)
    if let channels = activeObservers[observer as! NSObject] {
      for channel in channels {
        activeSubscriptions[channel] = activeSubscriptions[channel]! - 1
        if activeSubscriptions[channel] == 0 {
          evaluateJavaScript("if(window.removeIPadSubscription) window.removeIPadSubscription('\(channel)');", completionHandler: nil)
        }
      }
      activeObservers.removeValueForKey(observer as! NSObject)
      //println("Unsubscribed \(observer) from \(channels) so now have activeSubscriptions \(activeSubscriptions) activeObservers \(activeObservers)")
    }
  }
  
  func publish(channel: String, event: Dictionary<String, AnyObject>) {
    let serializedEvent = serializeData(event)
    evaluateJavaScript("Backbone.Mediator.publish('\(channel)', \(serializedEvent))", completionHandler: onJSEvaluated)
  }
  
  func evaluateJavaScript(js: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
    let handler = completionHandler == nil ? onJSEvaluated : completionHandler!  // There's got to be a more Swifty way of doing this.
    lastJSEvaluated = js
    //println(" evaluating JS: \(js)")
    webView?.evaluateJavaScript(js, completionHandler: handler)  // This isn't documented, so is it being added or removed or what?
  }
  
  func onJSEvaluated(response: AnyObject?, error: NSError?) {
    if error != nil {
      print("There was an error evaluating JS: \(error), response: \(response)")
      print("JS was \(lastJSEvaluated!)")
    } else if response != nil {
      //println("Got response from evaluating JS: \(response)")
    }
  }
  
  func onJSError(note: NSNotification) {
    if let event = note.userInfo {
      let message = event["message"]! as! String
      print("💔💔💔 Unhandled JS error in application: \(message)")
    }
  }

  func onNavigated(note: NSNotification) {
    if let event = note.userInfo {
      let route = event["route"]! as! String
      currentFragment = route
    }
  }

  private func serializeData(data: NSDictionary?) -> String {
    var serialized: NSData?
    if data != nil {
      do {
        serialized = try NSJSONSerialization.dataWithJSONObject(data!, options: NSJSONWritingOptions(rawValue: 0))
      } catch {
        serialized = nil
      }
    } else {
      let EmptyObjectString = NSString(string: "{}")
      serialized = EmptyObjectString.dataUsingEncoding(NSUTF8StringEncoding)
    }
    return NSString(data: serialized!, encoding: NSUTF8StringEncoding)! as String
  }
  
  func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    if message.name == "backboneEventHandler" {
      // Turn Backbone events into NSNotifications
      let body = (message.body as! NSDictionary) as Dictionary  // You... It... So help me...
      let channel = body["channel"] as! String
      let event = (body["event"] as! NSDictionary) as Dictionary
      //println("got backbone event: \(channel)")
      scriptMessageNotificationCenter.postNotificationName(channel, object: self, userInfo: event)
    } else if message.name == "consoleLogHandler" {
      let body = (message.body as! NSDictionary) as Dictionary
      let level = body["level"] as! String
      let arguments = body["arguments"] as! NSArray
      let message = arguments.componentsJoinedByString(" ")
      print("\(colorEmoji[level]!) \(level): \(message)")
    }
    else {
      print("got message: \(message.name): \(message.body)")
      scriptMessageNotificationCenter.postNotificationName(message.name, object: self, userInfo: message.body as? [NSObject:AnyObject])
    }
  }
  
  func addScriptMessageHandlers() {
    let contentController = webViewConfiguration!.userContentController
    contentController.addScriptMessageHandler(self, name: "backboneEventHandler")
    contentController.addScriptMessageHandler(self, name: "consoleLogHandler")
  }
  
  func onWebKitCheckupAnswered(response: AnyObject?, error: NSError?) {
    if response != nil {
      webKitCheckupsMissed = -1
      //println("WebView just checked in with response \(response), error \(error?)")
    }
    else {
      print("WebKit missed a checkup. It's either slow to respond, or has crashed. (Probably just slow to respond.)")
      webKitCheckupsMissed = 100
    }
  }
  
  func checkWebKit() {
    //println("webView is \(webView?); asking it to check in")
    if webKitCheckupsMissed > 60 {
      print("-----------------Oh snap, it crashed!---------------------")
      webKitCheckupsMissed = -1
      reloadWebView()
    }
    ++webKitCheckupsMissed;
    evaluateJavaScript("2 + 2;", completionHandler: onWebKitCheckupAnswered)
  }
  
  func reloadWebView() {
    let oldSuperView = webView!.superview
    if oldSuperView != nil {
      webView!.removeFromSuperview()
    }
    afterLoginFragment = currentFragment
    webView = nil
    instantiateWebView()
    if oldSuperView != nil {
      oldSuperView?.addSubview(webView!)
    }
    print("WebManager reloaded webview: \(webView!)")
    NSNotificationCenter.defaultCenter().postNotificationName("webViewReloadedFromCrash", object: self)
  }

}

private let WebManagerSharedInstance = WebManager()

let colorEmoji = ["debug": "📘", "log": "📓", "info": "📔", "warn": "📙", "error": "📕"]
