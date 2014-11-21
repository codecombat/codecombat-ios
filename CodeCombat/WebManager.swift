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
  //let rootURL = NSURL(scheme: "http", host: "localhost:3000", path: "/")
  //let rootURL = NSURL(scheme: "http", host: "10.0.1.2:3000", path: "/")
  let rootURL = NSURL(scheme: "http", host: "codecombat.com:80", path: "/")
  let allowedRoutePrefixes:[String] = ["http://localhost:3000","http://10.0.1.2:3000","http://codecombat.com/play"]
  var operationQueue: NSOperationQueue?
  var webView: WKWebView?  // Assign this if we create one, so that we can evaluate JS in its context.
  var lastJSEvaluated: String?
  var scriptMessageNotificationCenter:NSNotificationCenter!
  var activeSubscriptions: [String: Int] = [:]
  var activeObservers: [NSObject : [String]] = [:]
  var loginProtectionSpace:NSURLProtectionSpace?
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
    if hostReachibility.currentReachabilityStatus().value == NotReachable.value {
      println("Host unreachable")
      NSNotificationCenter.defaultCenter().postNotificationName("websiteNotReachable", object: nil)
    } else {
      println("Host reachable!")
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
  
  func createLoginProtectionSpace() {
    // http://stackoverflow.com/a/17997943/540620
    let url = rootURL
    loginProtectionSpace = NSURLProtectionSpace(host: url!.host!, port: url!.port!.integerValue, `protocol`: url!.scheme!, realm: nil, authenticationMethod: nil)  //.HTTPDigest)
  }
  
  func saveUser() {
    let credential = NSURLCredential(user: User.sharedInstance.email!, password: User.sharedInstance.password!, persistence: .Permanent)
    NSURLCredentialStorage.sharedCredentialStorage().setCredential(credential, forProtectionSpace: loginProtectionSpace!)
  }
  
  func clearCredentials() {
    let credentialsValues = getCredentials()
    for credential in credentialsValues {
      NSURLCredentialStorage.sharedCredentialStorage().removeCredential(credential, forProtectionSpace: loginProtectionSpace!)
    }
  }
  
  func getCredentials() -> [NSURLCredential] {
    let credentialsDictionary = NSURLCredentialStorage.sharedCredentialStorage().credentialsForProtectionSpace(loginProtectionSpace!)
    if credentialsDictionary == nil {
      return []
    }
    return credentialsDictionary!.values.array as [NSURLCredential]
  }
  
  func loginToGetAuthCookie(#username:String, password:String) {
    let loginURL = NSURL(string: "/auth/login", relativeToURL: rootURL)!
    
    let loginRequest = NSMutableURLRequest(URL: loginURL)
    loginRequest.HTTPMethod = "POST"
    loginRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
  
    let loginCredentials:[String:String] = ["username":username, "password":password]
    let postData = NSJSONSerialization.dataWithJSONObject(loginCredentials, options: NSJSONWritingOptions.allZeros, error: nil)
    loginRequest.HTTPBody = postData
    NSURLConnection.sendAsynchronousRequest(loginRequest, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
      if error != nil {
        dispatch_async(dispatch_get_main_queue(), {
          println("Web manager failed to log in")
          NSNotificationCenter.defaultCenter().postNotificationName("loginFailure", object: nil)
        })
      } else {
        self.authCookieIsFresh = true
        dispatch_async(dispatch_get_main_queue(), {
          println("Web manager successfully logged in")
          NSNotificationCenter.defaultCenter().postNotificationName("loginSuccess", object: nil)
        })
      }
    }
  }
  
  private func instantiateWebView() {
    let WebViewFrame = CGRectMake(0, 0, 1024, 768)  // Full-size
    webViewConfiguration = WKWebViewConfiguration()
    addScriptMessageHandlers()
    webView = WKWebView(frame: WebViewFrame, configuration: webViewConfiguration)
    webView!.navigationDelegate = self
    if let email = User.sharedInstance.email {
      logIn(email: email, password: User.sharedInstance.password!)
    }
  }
  
  func removeAllUserScripts() {
    webViewConfiguration!.userContentController.removeAllUserScripts()
  }
  
  func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
    println("Comitted navigation to \(webView.URL)")
    if !routeURLHasAllowedPrefix(webView.URL!.absoluteString!) {
      webView.stopLoading()
      webView.loadRequest(NSURLRequest(URL: NSURL(string: "/play", relativeToURL: rootURL)!))
    } else {
      //Inject the no-zoom javascript
      let noZoomJS = "var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);"
      webView.evaluateJavaScript(noZoomJS, completionHandler: nil)
      println("webView didCommitNavigation")
    }
    currentFragment = self.webView!.URL!.path!
  }
  
  func routeURLHasAllowedPrefix(route:String) -> Bool {
    var hasAllowedRoute = false
    for allowedPrefix in allowedRoutePrefixes {
      if route.hasPrefix(allowedPrefix) {
        return true
      }
    }
    return false
  }

  func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    NSNotificationCenter.defaultCenter().postNotificationName("webViewDidFinishNavigation", object: nil)
    println("webView didFinishNavigation")
    for (channel, count) in activeSubscriptions {
      if count > 0 {
        println("Reregistering \(channel)")
        registerSubscription(channel)
      }
    }
    if afterLoginFragment != nil {
      println("Now that we have logged in, we are navigating to \(afterLoginFragment!)")
      publish("router:navigate", event: ["route": afterLoginFragment!])
      afterLoginFragment = nil
    }
  }
  
  func logIn(#email: String, password: String) {
    let loginScript = "function foobarbaz() { require('/lib/auth').loginUser({'email':'\(email)','password':'\(password)'}); } if(me.get('anonymous') && !me.get('iosIdentifierForVendor')) setTimeout(foobarbaz, 1);"
    let userScript = WKUserScript(source: loginScript, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
    webViewConfiguration!.userContentController.addUserScript(userScript)
    let requestURL = NSURL(string: "/play", relativeToURL: rootURL)
    let request = NSMutableURLRequest(URL: requestURL!)
    webView!.loadRequest(request)
    //println("going to log in to \(requestURL) when web view loads! \(loginScript)")
  }
  
  //requires that User.email and User.password are set
  func createAnonymousUser() {
    //should include something
    let creationScript = "function makeAnonymousUser() { me.set('iosIdentifierForVendor','\(User.sharedInstance.email!)'); me.set('password','\(User.sharedInstance.password!)'); me.save();} if (!me.get('iosIdentifierForVendor') && me.get('anonymous')) setTimeout(makeAnonymousUser,1);"
    println("Injecting script \(creationScript)")
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
    if activeObservers[observer as NSObject] == nil {
      activeObservers[observer as NSObject] = []
    }
    activeObservers[observer as NSObject]!.append(channel)
    if activeSubscriptions[channel] == 1 {
      registerSubscription(channel)
    }
    //println("Subscribed \(observer) to \(channel) so now have activeSubscriptions \(activeSubscriptions) activeObservers \(activeObservers)")
  }
  
  private func registerSubscription(channel: String) {
    evaluateJavaScript("\n".join([
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
      ]), completionHandler: nil)
  }
  
  func unsubscribe(observer: AnyObject) {
    scriptMessageNotificationCenter.removeObserver(observer)
    if let channels = activeObservers[observer as NSObject] {
      for channel in channels {
        activeSubscriptions[channel] = activeSubscriptions[channel]! - 1
        if activeSubscriptions[channel] == 0 {
          evaluateJavaScript("if(window.removeIPadSubscription) window.removeIPadSubscription('\(channel)');", completionHandler: nil)
        }
      }
      activeObservers.removeValueForKey(observer as NSObject)
      //println("Unsubscribed \(observer) from \(channels) so now have activeSubscriptions \(activeSubscriptions) activeObservers \(activeObservers)")
    }
  }
  
  func publish(channel: String, event: Dictionary<String, AnyObject>) {
    let serializedEvent = serializeData(event)
    evaluateJavaScript("Backbone.Mediator.publish('\(channel)', \(serializedEvent))", onJSEvaluated)
  }
  
  func evaluateJavaScript(js: String, completionHandler: ((AnyObject!, NSError!) -> Void)!) {
    var handler = completionHandler == nil ? onJSEvaluated : completionHandler  // There's got to be a more Swifty way of doing this.
    lastJSEvaluated = js
    //println(" evaluating JS: \(js)")
    webView?.evaluateJavaScript(js, completionHandler: handler)  // This isn't documented, so is it being added or removed or what?
  }
  
  func onJSEvaluated(response: AnyObject!, error: NSError?) {
    if error != nil {
      println("There was an error evaluating JS: \(error), response: \(response)")
      println("JS was \(lastJSEvaluated!)")
    } else if response != nil {
      //println("Got response from evaluating JS: \(response)")
    }
  }
  
  func onJSError(note: NSNotification) {
    if let event = note.userInfo {
      let message = event["message"]! as String
      println("💔💔💔 Unhandled JS error in application: \(message)")
    }
  }

  func onNavigated(note: NSNotification) {
    if let event = note.userInfo {
      let route = event["route"]! as String
      currentFragment = route
    }
  }

  private func serializeData(data:NSDictionary?) -> String {
    var serialized:NSData?
    var error:NSError?
    if data != nil {
      serialized = NSJSONSerialization.dataWithJSONObject(data!, options: NSJSONWritingOptions(0), error: &error)
    } else {
      let EmptyObjectString = NSString(string: "{}")
      serialized = EmptyObjectString.dataUsingEncoding(NSUTF8StringEncoding)
    }
    return NSString(data: serialized!, encoding: NSUTF8StringEncoding)!
  }
  
  func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    if message.name == "backboneEventHandler" {
      // Turn Backbone events into NSNotifications
      let body = (message.body as NSDictionary) as Dictionary  // You... It... So help me...
      let channel = body["channel"] as NSString
      let event = (body["event"] as NSDictionary) as Dictionary
      //println("got backbone event: \(channel)")
      scriptMessageNotificationCenter.postNotificationName(channel, object: self, userInfo: event)
    } else if message.name == "consoleLogHandler" {
      let body = (message.body as NSDictionary) as Dictionary
      let level = body["level"] as NSString
      let arguments = body["arguments"] as NSArray
      let message = arguments.componentsJoinedByString(" ")
      println("\(colorEmoji[level]!) \(level): \(message)")
    }
    else {
      println("got message: \(message.name): \(message.body)")
      scriptMessageNotificationCenter.postNotificationName(message.name, object: self, userInfo: message.body as? NSDictionary)
    }
  }
  
  func addScriptMessageHandlers() {
    let contentController = webViewConfiguration!.userContentController
    contentController.addScriptMessageHandler(self, name: "backboneEventHandler")
    contentController.addScriptMessageHandler(self, name: "consoleLogHandler")
  }
  
  func onWebKitCheckupAnswered(response: AnyObject!, error: NSError?) {
    if response != nil {
      webKitCheckupsMissed = -1
      //println("WebView just checked in with response \(response), error \(error?)")
    }
    else {
      println("WebKit missed a checkup. It's either slow to respond, or has crashed. (Probably just slow to respond.)")
      webKitCheckupsMissed = 100
    }
  }
  
  func checkWebKit() {
    //println("webView is \(webView?); asking it to check in")
    if webKitCheckupsMissed > 60 {
      println("-----------------Oh snap, it crashed!---------------------")
      webKitCheckupsMissed = -1
      reloadWebView()
    }
    ++webKitCheckupsMissed;
    evaluateJavaScript("2 + 2;", completionHandler: onWebKitCheckupAnswered)
  }
  
  func reloadWebView() {
    var oldSuperView = webView!.superview
    if oldSuperView != nil {
      webView!.removeFromSuperview()
    }
    afterLoginFragment = currentFragment
    webView = nil
    instantiateWebView()
    if oldSuperView != nil {
      oldSuperView?.addSubview(webView!)
    }
    println("WebManager reloaded webview: \(webView!)")
    NSNotificationCenter.defaultCenter().postNotificationName("webViewReloadedFromCrash", object: self)
  }

}

private let WebManagerSharedInstance = WebManager()

let colorEmoji = ["debug": "📘", "log": "📓", "info": "📔", "warn": "📙", "error": "📕"]
//var emoji = "↖↗↘↙⏩⏪▶◀☀☁☎☔☕☝☺♈♉♊♋♌♍♎♏♐♑♒♓♠♣♥♦♨♿⚠⚡⚽⚾⛄⛎⛪⛲⛳⛵⛺⛽✂✈✊✋✌✨✳✴❌❎❓❔❕❗❤➡➿⬅⬆⬇⭐⭕〽㊗㊙🀄🅰🅱🅾🅿🆎🆒🆔🆕🆗🆙🆚🈁🈂🈚🈯🈳🈵🈶🈷🈸🈹🈺🉐🌀🌂🌃🌄🌅🌆🌇🌈🌊🌙🌟🌴🌵🌷🌸🌹🌺🌻🌾🍀🍁🍂🍃🍅🍆🍉🍊🍎🍓🍔🍘🍙🍚🍛🍜🍝🍞🍟🍡🍢🍣🍦🍧🍰🍱🍲🍳🍴🍵🍶🍸🍺🍻🎀🎁🎂🎃🎄🎅🎆🎇🎈🎉🎌🎍🎎🎏🎐🎑🎒🎓🎡🎢🎤🎥🎦🎧🎨🎩🎫🎬🎯🎰🎱🎵🎶🎷🎸🎺🎾🎿🏀🏁🏃🏄🏆🏈🏊🏠🏢🏣🏥🏦🏧🏨🏩🏪🏫🏬🏭🏯🏰🐍🐎🐑🐒🐔🐗🐘🐙🐚🐛🐟🐠🐤🐦🐧🐨🐫🐬🐭🐮🐯🐰🐱🐳🐴🐵🐶🐷🐸🐹🐺🐻👀👂👃👄👆👇👈👉👊👋👌👍👎👏👐👑👒👔👕👗👘👙👜👟👠👡👢👣👦👧👨👩👫👮👯👱👲👳👴👵👶👷👸👻👼👽👾👿💀💁💂💃💄💅💆💇💈💉💊💋💍💎💏💐💑💒💓💔💗💘💙💚💛💜💝💟💡💢💣💤💦💨💩💪💰💱💹💺💻💼💽💿📀📖📝📠📡📢📣📩📫📮📱📲📳📴📶📷📺📻📼🔊🔍🔑🔒🔓🔔🔝🔞🔥🔨🔫🔯🔰🔱🔲🔳🔴🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🗻🗼🗽😁😂😃😄😉😊😌😍😏😒😓😔😖😘😚😜😝😞😠😡😢😣😥😨😪😭😰😱😲😳😷🙅🙆🙇🙌🙏🚀🚃🚄🚅🚇🚉🚌🚏🚑🚒🚓🚕🚗🚙🚚🚢🚤🚥🚧🚬🚭🚲🚶🚹🚺🚻🚼🚽🚾🛀⏫⏬⏰⏳✅➕➖➗➰🃏🆑🆓🆖🆘🇦🇧🇨🇩🇪🇫🇬🇭🇮🇯🇰🇱🇲🇳🇴🇵🇶🇷🇸🇹🇺🇻🇼🇽🇾🇿🈲🈴🉑🌁🌉🌋🌌🌏🌑🌓🌔🌕🌛🌠🌰🌱🌼🌽🌿🍄🍇🍈🍌🍍🍏🍑🍒🍕🍖🍗🍠🍤🍥🍨🍩🍪🍫🍬🍭🍮🍯🍷🍹🎊🎋🎠🎣🎪🎭🎮🎲🎳🎴🎹🎻🎼🎽🏂🏡🏮🐌🐜🐝🐞🐡🐢🐣🐥🐩🐲🐼🐽🐾👅👓👖👚👛👝👞👤👪👰👹👺💌💕💖💞💠💥💧💫💬💮💯💲💳💴💵💸💾📁📂📃📄📅📆📇📈📉📊📋📌📍📎📏📐📑📒📓📔📕📗📘📙📚📛📜📞📟📤📥📦📧📨📪📰📹🔃🔋🔌🔎🔏🔐🔖🔗🔘🔙🔚🔛🔜🔟🔠🔡🔢🔣🔤🔦🔧🔩🔪🔮🔵🔶🔷🔸🔹🔼🔽🗾🗿😅😆😋😤😩😫😵😸😹😺😻😼😽😾😿🙀🙈🙉🙊🙋🙍🙎🚨🚩🚪🚫"