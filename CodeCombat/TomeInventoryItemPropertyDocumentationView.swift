//
//  TomeInventoryItemPropertyDocumentationView.swift
//  CodeCombat
//
//  Created by Nick Winter on 10/26/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import Foundation
import WebKit

class TomeInventoryItemPropertyDocumentationView: UIView {
  var item: TomeInventoryItem!
  var property: TomeInventoryItemProperty!
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  init(item: TomeInventoryItem, property: TomeInventoryItemProperty, coder aDecoder: NSCoder!) {
    self.item = item
    self.property = property
    super.init(coder: aDecoder)
    buildSubviews()
  }
  
  init(item: TomeInventoryItem, property: TomeInventoryItemProperty, frame: CGRect) {
    self.item = item
    self.property = property
    super.init(frame: frame)
    buildSubviews()
  }
  
  func buildSubviews() {
    var docWebView = WKWebView(frame: frame)
    var wrappedHTML = "<!DOCTYPE html>\n<html><head><meta name='viewport' content='width=320, height=480, initial-scale=1'><link rel='stylesheet' href='/stylesheets/app.css'></head><body><div class='tome-inventory-property-documentation'>\(property.docHTML)</div></body></html>"
    docWebView.loadHTMLString(wrappedHTML, baseURL: WebManagerSharedInstance.rootURL)
    addSubview(docWebView)
  }
}
