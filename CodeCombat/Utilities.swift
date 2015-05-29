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
  return content! as String
}

func parseJSONFile(filename: String) -> JSON {
  return JSON.parse(readResourceFile(filename))
}

// http://stackoverflow.com/a/24318861/540620
func delay(delay:Double, closure:()->()) {
  dispatch_after(
    dispatch_time(
      DISPATCH_TIME_NOW,
      Int64(delay * Double(NSEC_PER_SEC))
    ),
    dispatch_get_main_queue(), closure)
}