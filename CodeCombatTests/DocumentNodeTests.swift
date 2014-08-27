//
//  DocumentNodeTests.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/27/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation
import XCTest

class DocumentNodeTests: XCTestCase {
  
  var defaultNode:DocumentNode!
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    defaultNode = DocumentNode()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testInitiallyNoChildren() {
    XCTAssertEqual(defaultNode.children.count, 0, "The number of children of an initialized node should be zero")
  }
  
  func testInitiallyNameEmpty() {
    XCTAssertEqual(defaultNode.name, "", "The node should have an empty string as the name")
  }
  
  func testInitialRangeNil() {
    XCTAssertTrue(defaultNode.range == nil, "The range should initially be nil")
  }
  
  func testInitialSourceTextNil() {
    XCTAssertTrue(defaultNode.sourceText == nil, "The sourceText should initially be nil")
  }
  
  func testDefaultNodeDescription() {
    XCTAssertEqual(defaultNode.description(), "", "The description on an empty node should return an empty string")
  }
  
  func testNonDefaultDescription() {
    var exampleString:NSString = "This is a test string intended to test some of the functions of DocumentNodes."
    defaultNode.sourceText = exampleString
    defaultNode.range = NSRange(location: 0, length: 4)
    XCTAssertEqual(defaultNode.description(), "0-4: (no name) - Data: \"This\"\n")
  }
  
  func testGetData() {
    var exampleString:NSString = "Test String"
    defaultNode.sourceText = exampleString
    defaultNode.range = NSRange(location: 0, length: 4)
    XCTAssertEqual(defaultNode.data, "Test", "The data getter should work")
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock() {
      // Put the code you want to measure the time of here.
    }
    
  }
  
}
