//
//  ParticleScene.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/29/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit
import SpriteKit

class ParticleScene: SKScene {
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
    override init(size: CGSize) {
        super.init(size: size)
        self.backgroundColor = SKColor(red: 0.15, green: 0.15, blue: 0.3, alpha: 0.15)
      self.addChild(newExplosion(size.width/2, posY: size.height/2))
      
    }
    
    func newExplosion(posX:CGFloat, posY:CGFloat) -> SKEmitterNode {
        let emitter:SKEmitterNode = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("TestParticle", ofType: "sks")!) as SKEmitterNode
        emitter.position = CGPointMake(posX, posY)
        emitter.name = "explosion"
        emitter.targetNode = self.scene
        emitter.numParticlesToEmit = 1000
        emitter.zPosition=2.0
        return emitter
    }
    
}
