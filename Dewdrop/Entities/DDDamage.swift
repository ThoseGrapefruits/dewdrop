//
//  DDDamage.swift
//  Dewdrop
//
//  Created by Logan Moore on 9/16/23.
//

import Foundation
import SpriteKit

class DDDamage : SKShapeNode {
  init(arcWithBerth berth: CGFloat, andLength length: CGFloat) {
    let path = CGMutablePath()
    path.addLine(to: CGPoint(x: sin(berth) * length, y: cos(berth) * length))
    path.addLine(to: CGPoint(x: sin(berth) * length, y: -cos(berth) * length))
    path.addLine(to: CGPoint(x: 0, y: 0))
    super.init()
    self.path = path
    self.initPhysics()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  func initPhysics() {
    self.physicsBody = SKPhysicsBody(polygonFrom: path!)
    self.physicsBody!.contactTestBitMask = DDBitmask.damage.rawValue
  }
}
