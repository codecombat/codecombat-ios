//
//  PlayViewChildViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/30/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import WebKit

class PlayViewChildViewController: UIViewController, BackbonePublisher {
  
  var webView:WKWebView?
  var notificationCenter:NSNotificationCenter?
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func sendBackboneEvent(event:String, data:NSDictionary?) {
    let SerializedData = serializeData(data)
    var script:String
    if data != nil {
      script = "Backbone.Mediator.publish('\(event)',\(SerializedData));"
    } else {
      script = "Backbone.Mediator.publish('\(event)');"
    }
    
    webView?.evaluateJavaScript(script, completionHandler: nil)
  }
  
  private func serializeData(data:NSDictionary?) -> String {
    var serialized:NSData?
    var error:NSError?
    if data != nil {
      serialized = NSJSONSerialization.dataWithJSONObject(data!,
        options: NSJSONWritingOptions(0),
        error: &error)
    } else {
      let EmptyObjectString = NSString(string: "{}")
      serialized = EmptyObjectString.dataUsingEncoding(NSUTF8StringEncoding)
    }
    return NSString(data: serialized!, encoding: NSUTF8StringEncoding)
  }

}
