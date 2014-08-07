//
//  Utilities.swift
//  CodeCombat
//
//  Created by Nick Winter on 8/7/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation

func decodeJSON(json: String) -> AnyObject! {
  var data = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
  return NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil)
}

func readResourceFile(filename: String, type: String="json") -> String {
  let bundle = NSBundle.mainBundle()
  let path = bundle.pathForResource(filename, ofType: type)
  let content = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
  return content
}

func decodeJSONFile(filename: String) -> AnyObject! {
  return decodeJSON(readResourceFile(filename))
}