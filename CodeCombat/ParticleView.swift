//
//  ParticleView.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/29/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import SpriteKit

class ParticleView: SKView {

    var particleScene:SKScene?
    required init(coder aDecoder: NSCoder)  {
        super.init(coder: aDecoder)
        startParticles()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Initialization code
        startParticles()
    }
    
    func startParticles() {
        self.showsFPS = true
        self.showsNodeCount = true
        self.allowsTransparency = true
        
        particleScene = ParticleScene(size: self.bounds.size)
        particleScene!.scaleMode = SKSceneScaleMode.AspectFill
        particleScene!.backgroundColor = UIColor.clearColor()
        self.presentScene(particleScene!)
        
    }
    

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent!) -> UIView? {
        let hitView:UIView = super.hitTest(point, withEvent: event)!
        if hitView == self {
            return nil
        }
        return hitView
    }
    

}
