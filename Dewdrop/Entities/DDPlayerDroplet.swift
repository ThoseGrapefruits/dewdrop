//
//  DDPlayerDroplet.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit

enum DDDropletLock {
  case none
  
  case banishing
  case chambering
  case evaporating
}

class DDPlayerDroplet : SKShapeNode, DDPhysicsNode {
  static let MASS: CGFloat = 0.5
  static let RADIUS: CGFloat = 4.2

  weak private(set) var lastOwner: DDPlayerNode? = .none
  weak private(set) var owner:     DDPlayerNode? = .none
  
  var lock: DDDropletLock = .none

  func onCatch(by newOwner: DDPlayerNode) {
    owner = newOwner
    lock = .none
  }

  func onRelease() {
    lastOwner = owner
    owner = nil
    lock = .none
  }
  
  // MARK: DDPhysicsNode

  func initPhysics() {
    if physicsBody == nil {
      physicsBody = SKPhysicsBody(circleOfRadius: DDPlayerDroplet.RADIUS)
    }

    physicsBody!.linearDamping = 1
    physicsBody!.isDynamic = true
    physicsBody!.affectedByGravity = true
    physicsBody!.friction = 0.5
    physicsBody!.mass = DDPlayerDroplet.MASS
    physicsBody!.categoryBitMask = DDBitmask.playerDroplet
    physicsBody!.collisionBitMask =
      DDBitmask.ALL ^ DDBitmask.playerGun
    physicsBody!.contactTestBitMask =
      DDBitmask.playerDroplet ^ DDBitmask.ground
  }
}
