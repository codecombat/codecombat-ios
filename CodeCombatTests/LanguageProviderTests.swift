//
//  LanguageProviderTests.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 8/27/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation
import XCTest

class LanguageProviderTests: XCTestCase {
  
  var defaultProvider = LanguageProvider()
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    defaultProvider = LanguageProvider()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testScopesInitiallyEmpty() {
    XCTAssertEqual(defaultProvider.scope.count, 0, "The scopes should initially be empty")
  }
  
  func testGetNonexistentLanguage() {
    let lang = defaultProvider.getLanguage("nonexistentlanguage")
    XCTAssertTrue(lang == nil, "The getLanguage method should return nil if a language doesn't exist")
  }
  
  func testLanguageFromFileReturnsNilWithNonexistentFile() {
    let lang = defaultProvider.languageFromFile("nonexistentlanguage")
    XCTAssertTrue(lang == nil, "languageFromFile should return nil if the language file doesn't exist")
  }
  
  func testLanguageFromScopeReturnsNilWithNonExistentScope() {
    let lang = defaultProvider.languageFromFile("nonexistentlanguage")
    XCTAssertTrue(lang == nil, "languageFromScope should return nil if the scope/file doesn't exist")
  }
  
  func testGetLanguage() {
    let lang = defaultProvider.getLanguage("javascript")
    XCTAssertTrue(lang != nil, "The language shouldn't be nil")
  }
  
  func testLanguageParsing() {
    let lang = defaultProvider.getLanguage("javascript")!
    XCTAssertEqual(lang.fileTypes, ["js","htc","jsx"], "The filetypes should be set properly")
    XCTAssertEqual(lang.firstLineMatch, "^#!/.*\\b(node|js)", "The firstLineMatch should be set properly")
    //just a test of whether the regexes compile out of the box
    let compiledFirstLineMatch = OnigRegexp.compile(lang.firstLineMatch)
    XCTAssertEqual(compiledFirstLineMatch.search("#!/env/node").bodyRange().location, 0, "The firstLineMatch should match")
    XCTAssertEqual(lang.scopeName, "source.js", "The scopeName should be set")
    XCTAssertEqual(lang.rootPattern.patterns.count, 4, "There should be 4 root patterns")
    //now test the repository parsing
    let testRepositoryPattern = lang.repository["literal-arrow-function-storage"]!
    XCTAssertEqual(testRepositoryPattern.patterns.count, 1)
    let testNestedPattern = testRepositoryPattern.patterns[0]
    XCTAssertEqual(testNestedPattern.endCaptures[0].name, "storage.type.function.arrow.js")
    XCTAssertEqual(testNestedPattern.endCaptures[0].key, 1)
    XCTAssertEqual(testNestedPattern.begin.regex.expression(), "(?x)\n  (?=\\([^())]*\\)\\s*(=>))")
    XCTAssertEqual(testNestedPattern.end.regex.expression(), "(?<=\\))\\s*(=>)")
    XCTAssertEqual(testNestedPattern.name, "meta.function.arrow.js")
    XCTAssertEqual(testNestedPattern.patterns.count, 1)
    XCTAssertEqual(testNestedPattern.patterns[0].include, "#function-declaration-parameters")
  }
  
  func testLanguageParsePerformance() {
    self.measureBlock() {
      let lang = self.defaultProvider.getLanguage("javascript")!
    }
  }
}
