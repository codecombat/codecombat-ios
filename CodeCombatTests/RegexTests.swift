//
//  RegexTests.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/29/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import XCTest

class RegexTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testBasicRegex() {
    let regex = Regex()
    regex.regex = OnigRegexp.compile("\\b(var|let|const)\\b")
    let result = regex.find("var ", pos: 0)
    XCTAssertEqual(result!.body(), "var", "The body should be the matched text")
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock() {
      // Put the code you want to measure the time of here.
    }
  }
  
}
