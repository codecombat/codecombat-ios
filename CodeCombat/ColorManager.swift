//
//  Colors.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/27/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class ColorManager {
  let lightBrown:UIColor = UIColor(red: 229/256, green: 208/256, blue: 136/256, alpha: 1)
  let gutterBorder = UIColor(red: CGFloat(180.0/256.0),green: CGFloat(166.0/256.0),blue: CGFloat(146.0/256.0),alpha: 1)
  let darkBrown:UIColor = UIColor(red: 80/256, green: 64/256, blue: 50/256, alpha: 1)
  let grassGreen:UIColor = UIColor(red: 146/256, green: 202/256, blue: 54/256, alpha: 1)
    
    class var sharedInstance:ColorManager {
        return colorManagerSharedInstance
    }
}

let colorManagerSharedInstance = ColorManager()