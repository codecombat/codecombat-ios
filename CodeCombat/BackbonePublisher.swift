//
//  BackbonePublisher.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/30/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//
import WebKit
protocol BackbonePublisher {
  var webView:WKWebView? { get }
  func sendBackboneEvent(event:String, data:NSDictionary?)
}