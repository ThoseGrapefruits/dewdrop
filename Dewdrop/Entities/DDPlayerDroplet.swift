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
  
  case chambering
  case disowning
  case evaporating
}

class DDPlayerDroplet : SKShapeNode, DDPhysicsNode {
  static let MASS: CGFloat = 0.5
  static let RADIUS: CGFloat = 4.2

  weak private(set) var lastOwner: DDPlayerNode? = .none
  weak private(set) var owner:     DDPlayerNode? = .none
  
  var lock: DDDropletLock = .none
  
  // MARK: SKNode

  override var name: String? {
    get { "DDPlayerDroplet (\(owner?.name ?? "ownerless"))" }
    set {}
  }

  // MARK: API

  func destroy() {
    owner?.disown(wetChild: self)
    onRelease()
    removeFromParent()
  }

  // MARK: Handlers

  func onCatch(by newOwner: DDPlayerNode) {
    owner = newOwner
    lock = .none
  }

  func onRelease() {
    lastOwner = owner
    owner = .none
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
    physicsBody!.restitution = 0
    physicsBody!.mass = DDPlayerDroplet.MASS
    physicsBody!.categoryBitMask = DDBitmask.playerDroplet.rawValue
    physicsBody!.collisionBitMask =
      DDBitmask.ALL.rawValue ^
      DDBitmask.playerGun.rawValue
    physicsBody!.contactTestBitMask =
      DDBitmask.playerDroplet.rawValue ^
      DDBitmask.ground.rawValue ^
      DDBitmask.death.rawValue
  }
}
