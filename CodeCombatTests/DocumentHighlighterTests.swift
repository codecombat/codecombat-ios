//
//  DocumentTests.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/27/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation
import XCTest

class DocumentHighlighterTests: XCTestCase {
  
  var documentHighlighter = DocumentHighlighter()
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    documentHighlighter = DocumentHighlighter()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testSimpleExampleParsing() {
    let provider = LanguageProvider()
    let parser = LanguageParser(scope: "example", data: "char const* str = \"Hello world\\n\"", provider: provider)
    let parseRootNode = parser.parse()
    //write more tests here for example
    XCTAssertTrue(parseRootNode != nil, "The parse root node shouldn't be nil")
  }
  
  func testSimpleJavascriptParsing() {
    let provider = LanguageProvider()
    let parser = LanguageParser(scope: "javascript", data: "var blah = 5; var test = function() { console.log(\"Hello World\");};", provider: provider)
    let parseRootNode = parser.parse()
    XCTAssertTrue(parseRootNode != nil, "The parse root node shouldn't be nil.")
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock() {
      // Put the code you want to measure the time of here.
    }
  }
  
}
