//
//  DDGun.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit

class DDGun : SKShapeNode {
  static let LAUNCH_FORCE: CGFloat = 400.0

  var chambered: Optional<DDPlayerDroplet> = .none
  var chamberedCollisionBitmask: UInt32 = UInt32.zero
  var chamberedCategoryBitmask: UInt32 = UInt32.zero

  override init() {
    super.init()

    fillColor = .systemGreen
    strokeColor = .green
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func chamberDroplet(_ droplet: DDPlayerDroplet) {
    chambered = droplet
    strokeColor = .white

    if let dropletPhysicsBody = droplet.physicsBody {
      chamberedCategoryBitmask = dropletPhysicsBody.categoryBitMask
      chamberedCollisionBitmask = dropletPhysicsBody.collisionBitMask

      dropletPhysicsBody.categoryBitMask = DDBitmask.none
      dropletPhysicsBody.collisionBitMask = DDBitmask.none
    }

    droplet.removeFromParent()
    addChild(droplet)

    droplet.physicsBody?.pinned = true
    droplet.position = CGPoint(x: 24.0, y: 0.0)
  }

  func fireDroplet() {
    guard let chambered = chambered else {
      return
    }

    strokeColor = .green

    let scenePosition = chambered.getPosition(within: scene!)

    // Reparent to scene but keep scene-relative position
    chambered.removeFromParent()
    chambered.onRelease()
    scene?.addChild(chambered)
    chambered.position = scenePosition

    guard let chamberedPhysicsBody = chambered.physicsBody else {
      return
    }

    // Reset the physics bitmasks
    if chamberedCollisionBitmask != UInt32.zero {
      chamberedPhysicsBody.collisionBitMask = chamberedCollisionBitmask
    }

    if (chamberedCategoryBitmask != UInt32.zero) {
      chamberedPhysicsBody.categoryBitMask = chamberedCategoryBitmask
    }

    chamberedCategoryBitmask = UInt32.zero
    chamberedCollisionBitmask = UInt32.zero

    let launchAngle = getRotation(within: scene!)
    // Apply launch force
    chamberedPhysicsBody.pinned = false
    chamberedPhysicsBody.applyImpulse(CGVector(
      dx: cos(launchAngle) * DDGun.LAUNCH_FORCE,
      dy: sin(launchAngle) * DDGun.LAUNCH_FORCE))
  }
}
