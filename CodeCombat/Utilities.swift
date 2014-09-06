//
//  Utilities.swift
//  CodeCombat
//
//  Created by Nick Winter on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

func readResourceFile(filename: String, type: String="json") -> String {
  let bundle = NSBundle.mainBundle()
  let path = bundle.pathForResource(filename, ofType: type)
  let content = NSString(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: nil)
  return content
}

func parseJSONFile(filename: String) -> JSON {
  return JSON.parse(readResourceFile(filename))
}

func sendBackboneEvent(event:String, data:NSDictionary?) {
  let SerializedData = serializeData(data)
  var script:String
  if data != nil {
    script = "Backbone.Mediator.publish('\(event)',\(SerializedData));"
  } else {
    script = "Backbone.Mediator.publish('\(event)');"
  }
  evaluateJavaScript(script);
}

func evaluateJavaScript(js:String) {
  NSNotificationCenter.defaultCenter().postNotificationName("Evaluate JavaScript", object: nil, userInfo: ["js": js])
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
