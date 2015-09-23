//
//  IAPHelper.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/30/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import StoreKit

let IAPHelperProductPurchasedNotification:String = "IAPHelperProductPurchasedNotification"

//thanks http://www.raywenderlich.com/21081/introduction-to-in-app-purchases-in-ios-6-tutorial
class IAPHelper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver{
  
  var productsRequest:SKProductsRequest?
  var completionHandler:((Bool,NSArray) -> Void)?
  var productIdentifiers:Set<String>!
  var productsDict:[String:SKProduct] = [:]
  
  init(productIdentifiers:Set<String>)  {
    super.init()
    self.productIdentifiers = productIdentifiers
    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
  }
  
  func requestProductsWithCompletionHandler(handler:((Bool,NSArray) -> Void)) {
    self.completionHandler = handler
    print("Requesting products \(productIdentifiers)")
    productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
    productsRequest?.delegate = self
    productsRequest?.start()
  }
  
  func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse)  {
    print("Loaded list of products")
    self.productsRequest = nil
    
    let skproducts = response.products
    for product in skproducts {
      productsDict[product.productIdentifier] = product
    }
    self.completionHandler?(true, skproducts)
    completionHandler = nil
  }
  
  func request(request: SKRequest, didFailWithError error: NSError)  {
    productsRequest = nil
    self.completionHandler?(false, NSArray())
    self.completionHandler = nil
  }
  
  func buyProduct(product:SKProduct) {
    let payment = SKPayment(product: product)
    SKPaymentQueue.defaultQueue().addPayment(payment)
  }

  func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .Purchased:
        completeTransaction(transaction)
        break
      case .Failed:
        failedTransaction(transaction)
        break
      case .Restored:
        restoreTransaction(transaction)
        break
      case .Purchasing:
        print("Purchasing!")
      default:
        break
      }
      
    }
  }
  
  func localizedPriceForProduct(product:SKProduct) -> String {
    let priceFormatter = NSNumberFormatter()
    priceFormatter.formatterBehavior = NSNumberFormatterBehavior.Behavior10_4
    priceFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
    
    priceFormatter.locale = product.priceLocale
    return priceFormatter.stringFromNumber(product.price)!
  }
  
  func completeTransaction(transaction:SKPaymentTransaction) {
    if WebManager.sharedInstance.authCookieIsFresh {
      if NSBundle.mainBundle().appStoreReceiptURL == nil {
        print("No app store receipt URL exists!")
        return
      }
      let receiptData = NSData(contentsOfURL: NSBundle.mainBundle().appStoreReceiptURL!)
      //let receiptDict
      if receiptData == nil {
        print("There was an error encoding the receipt data!")
        return
      }
      let receiptString = receiptData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
      var receiptDict:[String:[String:String]] = [:]
      var innerDict:[String:String] = [:]
      innerDict["rawReceipt"] = receiptString
      let purchasedProduct = CodeCombatIAPHelper.sharedInstance.productsDict[transaction.payment.productIdentifier]
      if purchasedProduct == nil {
        CodeCombatIAPHelper.sharedInstance.requestProductsWithCompletionHandler({success, products in
          self.completeTransaction(transaction)
        })
        return
      }
      
      innerDict["localPrice"] = localizedPriceForProduct(purchasedProduct!)
      innerDict["transactionID"] = transaction.transactionIdentifier
      receiptDict["apple"] = innerDict
      sendGemRequestToCodeCombatServers(receiptDict, transaction: transaction)
    } else {
      print("Auth cookie is not fresh, trying transaction again later...")
    }
    
  }
  
  func sendGemRequestToCodeCombatServers(receiptDict:[String:[String:String]], transaction:SKPaymentTransaction) {
    let error:NSErrorPointer = nil
    let postData: NSData?
    do {
      postData = try NSJSONSerialization.dataWithJSONObject(receiptDict, options: NSJSONWritingOptions())
    } catch var error1 as NSError {
      error.memory = error1
      postData = nil
    }
    if error != nil {
      print("Error serializing gem request!")
      return
    }
    let request = NSMutableURLRequest(URL: NSURL(string: "/db/payment", relativeToURL: WebManager.sharedInstance.rootURL)!)
    request.HTTPMethod = "POST"
    request.HTTPBody = postData!
    print("Sending request \(postData)")
    print(receiptDict)
    let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(WebManager.sharedInstance.rootURL!)
    let headers = NSHTTPCookie.requestHeaderFieldsWithCookies(cookies!)
    request.allHTTPHeaderFields = headers
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response:NSURLResponse?, data:NSData?, error:NSError?) -> Void in
      if error != nil {
        print("There was an error \(error.localizedDescription)")
        let errorString = NSString(data: data, encoding: NSUTF8StringEncoding)
        print("Error data: \(errorString)")
      } else {
        var jsonError:NSErrorPointer = nil
        var paymentJSON = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? NSDictionary
        if jsonError != nil || paymentJSON == nil {
          print("There was an error serializing the JSON")
          print(jsonError)
        } else {
          print("Should finish transaction here....")
          var userInfo:[String:String!] = [:]
          if transaction.payment != nil && transaction.payment.productIdentifier != nil {
            let productID = transaction.payment.productIdentifier
            userInfo = ["productID":productID]
          }
          NSNotificationCenter.defaultCenter().postNotificationName("productPurchased", object: nil, userInfo: userInfo)
          SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        }
      }
    }
    
    
  }
  
  func restoreTransaction(transaction:SKPaymentTransaction) {
    print("Restore transaction")
    var userInfo:[String:String] = [:]
    if transaction.payment != nil && transaction.payment.productIdentifier != nil {
      let productID = transaction.payment.productIdentifier
      userInfo = ["productID":productID]
    }
    NSNotificationCenter.defaultCenter().postNotificationName("productPurchased", object: nil, userInfo: userInfo)
    SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    
  }
  
  func failedTransaction(transaction:SKPaymentTransaction) {
    print("Failed transaction")
    if transaction.error.code != SKErrorPaymentCancelled {
      print("Transaction error: \(transaction.error.localizedDescription)")
    }
    SKPaymentQueue.defaultQueue().finishTransaction(transaction)
  }
  
  func restoreCompletedTransactions() {
    SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
  }
}
