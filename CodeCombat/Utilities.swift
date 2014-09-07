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
