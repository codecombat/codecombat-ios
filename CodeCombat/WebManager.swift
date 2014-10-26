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
  var operationQueue: NSOperationQueue?
  var webView: WKWebView?  // Assign this if we create one, so that we can evaluate JS in its context.
  var lastJSEvaluated: String?
  var scriptMessageNotificationCenter:NSNotificationCenter!
  var activeSubscriptions: [String: Int] = [:]
  var activeObservers: [NSObject : [String]] = [:]
  
  class var sharedInstance:WebManager {
    return WebManagerSharedInstance
  }

  override init() {
    super.init()
    operationQueue = NSOperationQueue()
    scriptMessageNotificationCenter = NSNotificationCenter()
    instantiateWebView()
    subscribe(self, channel: "application:error", selector: "onJSError:")
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
  
  func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
    //Inject the no-zoom javascript
    let noZoomJS = "var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);"
    webView.evaluateJavaScript(noZoomJS, completionHandler: nil)
    println("Evaluated no-zoom Javascript")
  }
  
  func logIn(#email: String, password: String) {
    let loginScript = "function foobarbaz() { require('/lib/auth').loginUser({'email':'\(email)','password':'\(password)'}); } if(me.get('anonymous')) setTimeout(foobarbaz, 1);"
    let userScript = WKUserScript(source: loginScript, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
    webViewConfiguration!.userContentController.addUserScript(userScript)
    let requestURL = NSURL(string: "/play", relativeToURL: rootURL)
    let request = NSMutableURLRequest(URL: requestURL!)
    webView!.loadRequest(request)
    //println("going to log in to \(requestURL) when web view loads! \(loginScript)")
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
    //println("Subscribed \(observer) to \(channel) so now have activeSubscriptions \(activeSubscriptions) activeObservers \(activeObservers)")
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
}

let WebManagerSharedInstance = WebManager()

let colorEmoji = ["debug": "📘", "log": "📓", "info": "📔", "warn": "📙", "error": "📕"]
//var emoji = "↖↗↘↙⏩⏪▶◀☀☁☎☔☕☝☺♈♉♊♋♌♍♎♏♐♑♒♓♠♣♥♦♨♿⚠⚡⚽⚾⛄⛎⛪⛲⛳⛵⛺⛽✂✈✊✋✌✨✳✴❌❎❓❔❕❗❤➡➿⬅⬆⬇⭐⭕〽㊗㊙🀄🅰🅱🅾🅿🆎🆒🆔🆕🆗🆙🆚🈁🈂🈚🈯🈳🈵🈶🈷🈸🈹🈺🉐🌀🌂🌃🌄🌅🌆🌇🌈🌊🌙🌟🌴🌵🌷🌸🌹🌺🌻🌾🍀🍁🍂🍃🍅🍆🍉🍊🍎🍓🍔🍘🍙🍚🍛🍜🍝🍞🍟🍡🍢🍣🍦🍧🍰🍱🍲🍳🍴🍵🍶🍸🍺🍻🎀🎁🎂🎃🎄🎅🎆🎇🎈🎉🎌🎍🎎🎏🎐🎑🎒🎓🎡🎢🎤🎥🎦🎧🎨🎩🎫🎬🎯🎰🎱🎵🎶🎷🎸🎺🎾🎿🏀🏁🏃🏄🏆🏈🏊🏠🏢🏣🏥🏦🏧🏨🏩🏪🏫🏬🏭🏯🏰🐍🐎🐑🐒🐔🐗🐘🐙🐚🐛🐟🐠🐤🐦🐧🐨🐫🐬🐭🐮🐯🐰🐱🐳🐴🐵🐶🐷🐸🐹🐺🐻👀👂👃👄👆👇👈👉👊👋👌👍👎👏👐👑👒👔👕👗👘👙👜👟👠👡👢👣👦👧👨👩👫👮👯👱👲👳👴👵👶👷👸👻👼👽👾👿💀💁💂💃💄💅💆💇💈💉💊💋💍💎💏💐💑💒💓💔💗💘💙💚💛💜💝💟💡💢💣💤💦💨💩💪💰💱💹💺💻💼💽💿📀📖📝📠📡📢📣📩📫📮📱📲📳📴📶📷📺📻📼🔊🔍🔑🔒🔓🔔🔝🔞🔥🔨🔫🔯🔰🔱🔲🔳🔴🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🗻🗼🗽😁😂😃😄😉😊😌😍😏😒😓😔😖😘😚😜😝😞😠😡😢😣😥😨😪😭😰😱😲😳😷🙅🙆🙇🙌🙏🚀🚃🚄🚅🚇🚉🚌🚏🚑🚒🚓🚕🚗🚙🚚🚢🚤🚥🚧🚬🚭🚲🚶🚹🚺🚻🚼🚽🚾🛀⏫⏬⏰⏳✅➕➖➗➰🃏🆑🆓🆖🆘🇦🇧🇨🇩🇪🇫🇬🇭🇮🇯🇰🇱🇲🇳🇴🇵🇶🇷🇸🇹🇺🇻🇼🇽🇾🇿🈲🈴🉑🌁🌉🌋🌌🌏🌑🌓🌔🌕🌛🌠🌰🌱🌼🌽🌿🍄🍇🍈🍌🍍🍏🍑🍒🍕🍖🍗🍠🍤🍥🍨🍩🍪🍫🍬🍭🍮🍯🍷🍹🎊🎋🎠🎣🎪🎭🎮🎲🎳🎴🎹🎻🎼🎽🏂🏡🏮🐌🐜🐝🐞🐡🐢🐣🐥🐩🐲🐼🐽🐾👅👓👖👚👛👝👞👤👪👰👹👺💌💕💖💞💠💥💧💫💬💮💯💲💳💴💵💸💾📁📂📃📄📅📆📇📈📉📊📋📌📍📎📏📐📑📒📓📔📕📗📘📙📚📛📜📞📟📤📥📦📧📨📪📰📹🔃🔋🔌🔎🔏🔐🔖🔗🔘🔙🔚🔛🔜🔟🔠🔡🔢🔣🔤🔦🔧🔩🔪🔮🔵🔶🔷🔸🔹🔼🔽🗾🗿😅😆😋😤😩😫😵😸😹😺😻😼😽😾😿🙀🙈🙉🙊🙋🙍🙎🚨🚩🚪🚫"