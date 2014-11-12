import UIKit
import StoreKit

class StoreViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  @IBOutlet weak var collectionView: UICollectionView!
  var products:[SKProduct]
  
  @IBAction func goBackToMainMenu(sender:AnyObject?) {
    dismissViewControllerAnimated(true, completion: nil)
    collectionView.reloadData()
  }
  
  required init(coder aDecoder: NSCoder) {
    products = []
    super.init(coder: aDecoder)
  }
  
  override func viewWillAppear(animated: Bool) {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("productPurchased:"), name: IAPHelperProductPurchasedNotification, object: nil)
  }
  
  override func viewWillDisappear(animated: Bool) {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  override func viewDidLoad() {
    CodeCombatIAPHelper.sharedInstance.requestProductsWithCompletionHandler({ [weak self] success, products -> Void in
      if success {
        self!.products = products as [SKProduct]
        self?.collectionView.reloadData()
      } else {
        println("Something went wrong in the store view controller")
      }
      })
    //self.collectionView.registerClass(NSClassFromString("UICollectionViewCell"), forCellWithReuseIdentifier: "InventoryCell")
  }
  
  func productPurchased(notification:NSNotification) {
    let productIdentifier = notification.object as String
    println("Should update store view here...")
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return products.count
  }

  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("InventoryCell", forIndexPath: indexPath) as InventoryCell
    cell.backgroundColor = UIColor.whiteColor()
    let product = products[indexPath.row]
    println("Getting product \(product.productIdentifier)")
    if product.productIdentifier == IAP.Gems5.rawValue {
      cell.imageView.image = UIImage(named: "amuletOfConditional")
    } else if product.productIdentifier == IAP.Gems10.rawValue {
      cell.imageView.image = UIImage(named: "gemOfNope")
    } else if product.productIdentifier == IAP.Gems20.rawValue {
      cell.imageView.image = UIImage(named:"wine")
    }
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
    
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let product = products[indexPath.row]
    
    performSegueWithIdentifier("ShowStoreItemDetails", sender: product)
    collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    let product = products[indexPath.row]
    let retval = CGSizeMake(100, 100)
    return retval
  }
  
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
    return UIEdgeInsetsMake(50, 20, 50, 20)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    if segue.identifier == "ShowStoreItemDetails" {
      let storeItemDetailViewController = segue.destinationViewController as StoreItemDetailViewController
      storeItemDetailViewController.product = sender as SKProduct
    }
  }
}
