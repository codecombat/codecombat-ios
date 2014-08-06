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
class IAPHelper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
  
  var productsRequest:SKProductsRequest?
  var completionHandler:((Bool,NSArray) -> Void)?
  var productIdentifiers:NSSet?
  var purchasedProductIdentifiers:NSMutableSet?
  
  
  init(productIdentifiers:NSSet)  {
    super.init()
    self.productIdentifiers = productIdentifiers
    purchasedProductIdentifiers = NSMutableSet()
    for productIdentifier in productIdentifiers {
      let PID = productIdentifier as String
      let purchased = NSUserDefaults.standardUserDefaults().boolForKey(PID)
      if purchased {
        purchasedProductIdentifiers!.addObject(PID)
        println("Previously purchased \(PID)")
      } else {
        println("Hasn't purchased \(PID)")
      }
    }
    
    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
  }
  
  func requestProductsWithCompletionHandler(handler:((Bool,NSArray) -> Void)) {
    self.completionHandler = handler
    productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
    productsRequest!.delegate = self
    productsRequest!.start()
  }
  func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!)  {
    println("Loaded list of products")
    self.productsRequest = nil
    
    let SKProducts = response.products as NSArray
    for product in SKProducts {
      println("Found product \(product)")
    }
    
    self.completionHandler?(true, SKProducts)
    completionHandler = nil
  }
  
  func request(request: SKRequest!, didFailWithError error: NSError!)  {
    println("Failed to load list of products")
    println(error)
    productsRequest = nil
    self.completionHandler!(false, NSArray())
    self.completionHandler = nil
  }
  
  func buyProduct(product:SKProduct) {
    println("Buying product \(product.productIdentifier)")
    let payment = SKPayment(product: product)
    SKPaymentQueue.defaultQueue().addPayment(payment)
  }
  
  func productPurchased(productIdentifier:String) -> Bool {
    return purchasedProductIdentifiers!.containsObject(productIdentifier)
  }
  
  func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
  
    for transaction in transactions as [SKPaymentTransaction] {
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
      default:
        break
      }
      
    }
  }
  
  func completeTransaction(transaction:SKPaymentTransaction) {
    println("Complete transaction")
    provideContentForProductIdentifier(transaction.payment.productIdentifier)
    SKPaymentQueue.defaultQueue().finishTransaction(transaction)
  }
  
  func restoreTransaction(transaction:SKPaymentTransaction) {
    println("Restore transaction")
    provideContentForProductIdentifier(transaction.originalTransaction.payment.productIdentifier)
    SKPaymentQueue.defaultQueue().finishTransaction(transaction)
  }
  
  func failedTransaction(transaction:SKPaymentTransaction) {
    println("Failed transaction")
    if transaction.error.code != SKErrorPaymentCancelled {
      println("Transaction error: \(transaction.error.localizedDescription)")
    }
    SKPaymentQueue.defaultQueue().finishTransaction(transaction)
  }
  
  func provideContentForProductIdentifier(productIdentifier:String) {
    purchasedProductIdentifiers!.addObject(productIdentifier)
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: productIdentifier)
    NSUserDefaults.standardUserDefaults().synchronize()
    NSNotificationCenter.defaultCenter().postNotificationName(IAPHelperProductPurchasedNotification, object: productIdentifier, userInfo: nil)
    println("HERE IS YO STUFF")
    
  }
  
  func restoreCompletedTransactions() {
    SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
  }
  
  

}
