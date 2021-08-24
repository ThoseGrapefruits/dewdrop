//
//  DDNodeSnapshot.swift
//  DDNodeSnapshot
//
//  Created by Logan Moore on 2021-08-23.
//

import Foundation
import SpriteKit


func setIfChanged<T : Equatable>(from old: T, to new: T) -> DDFieldChange<T>? {
  return old == new ? .none : DDFieldChange.set(new)
}

struct PhysicsBodySnapshot : Codable {
  var angularDamping: CGFloat
  var angularVelocity: CGFloat
  var linearDamping: CGFloat
  var mass: CGFloat
  var velocity: CGVector

  // MARK: Static API

  static func capture(_ physicsBody: SKPhysicsBody?) -> PhysicsBodySnapshot? {
    guard let physicsBody = physicsBody else {
      return .none
    }

    return PhysicsBodySnapshot(
      angularDamping: physicsBody.angularDamping,
      angularVelocity: physicsBody.angularVelocity,
      linearDamping: physicsBody.linearDamping,
      mass: physicsBody.mass,
      velocity: physicsBody.velocity)
  }

  // MARK: API

  func delta(from: PhysicsBodySnapshot?) -> PhysicsBodyDelta {
    guard let last = from else {
      return PhysicsBodyDelta(
        angularDamping: .set(angularDamping),
        angularVelocity: .set(angularVelocity),
        damping: .set(linearDamping),
        mass: .set(mass),
        velocity: .set(velocity))
    }

    return PhysicsBodyDelta(
      angularDamping: setIfChanged(
        from: angularDamping,
        to: last.angularDamping),
      angularVelocity: setIfChanged(
        from: angularVelocity,
        to: last.angularVelocity),
      damping: setIfChanged(
        from: linearDamping,
        to: last.linearDamping),
      mass: setIfChanged(
        from: mass,
        to: last.mass),
      velocity: setIfChanged(
        from: velocity,
        to: last.velocity)
      )
  }

  func restore(to physicsBody: SKPhysicsBody?) {
    guard let physicsBody = physicsBody else {
      return
    }

    physicsBody.angularDamping = angularDamping
    physicsBody.angularVelocity = angularVelocity
    physicsBody.linearDamping = linearDamping
    physicsBody.mass = mass
    physicsBody.velocity = velocity
  }
}

struct DDNodeSnapshot : Codable {

  // MARK: Stored fields

  var physicsBody: PhysicsBodySnapshot?
  var position: CGPoint
  var zPosition: CGFloat
  var zRotation: CGFloat

  // MARK: Static API

  static func capture(_ node: DDNode) -> DDNodeSnapshot {
    return DDNodeSnapshot(
      physicsBody: PhysicsBodySnapshot.capture(node.physicsBody),
      position: node.position,
      zPosition: node.zPosition,
      zRotation: node.zRotation)
  }

  // MARK: API

  func delta(from: DDNodeSnapshot?) -> DDNodeChange {
    guard let from = from else {
      return DDNodeChange.full(self)
    }

    return DDNodeChange.delta(DDNodeDelta(
      physicsBody: physicsBody?.delta(from: from.physicsBody),
      position: setIfChanged(from: from.position, to: position),
      zPosition: setIfChanged(from: from.zPosition, to: zPosition),
      zRotation: setIfChanged(from: from.zRotation, to: zRotation)
    ))
  }

  func restore(to node: DDNode) {
    physicsBody?.restore(to: node.physicsBody)

    node.position = position
    node.zPosition = zPosition
    node.zRotation = zRotation
  }
}
