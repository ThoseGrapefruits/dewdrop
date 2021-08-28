//
//  DDNodeDelta.swift
//  DDNodeDelta
//
//  Created by Logan Moore on 2021-08-23.
//

import Foundation
import SpriteKit

struct PhysicsBodyDelta : Codable {

  // MARK: SKPhysicsBody fields

  var angularDamping: DDFieldChange<CGFloat>
  var angularVelocity: DDFieldChange<CGFloat>
  var linearDamping: DDFieldChange<CGFloat>
  var mass: DDFieldChange<CGFloat>
  var velocity: DDFieldChange<CGVector>

  // MARK: API

  func apply(to physicsBody: SKPhysicsBody?) {
    guard let physicsBody = physicsBody else {
      return
    }

    physicsBody.angularDamping = angularDamping.apply(
      to: physicsBody.angularDamping)

    physicsBody.angularVelocity = angularVelocity.apply(
      to: physicsBody.angularVelocity)

    physicsBody.linearDamping = linearDamping.apply(
      to: physicsBody.linearDamping)

    physicsBody.mass = mass.apply(
      to: physicsBody.mass)

    physicsBody.velocity = velocity.apply(
      to: physicsBody.velocity)
  }
}

struct DDNodeDelta : Codable {

  // MARK: Network metadata

  var id: DDNodeID

  // MARK: SKNode fields

  var physicsBody: PhysicsBodyDelta?
  var position: DDFieldChange<CGPoint>
  var zPosition: DDFieldChange<CGFloat>
  var zRotation: DDFieldChange<CGFloat>

  // MARK: API

  func apply(to node: SKNode) {
    physicsBody?.apply(to: node.physicsBody)

    node.position = position.apply(to: node.position)
    node.zPosition = zPosition.apply(to: node.zPosition)
    node.zRotation = zRotation.apply(to: node.zRotation)
  }
}
