//
//  InventoryCell.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/31/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import StoreKit

class InventoryCell: UICollectionViewCell {
  @IBOutlet weak var imageView: UIImageView!
  var product:SKProduct?
}
