//
//  DDLeafHost.swift
//  Dewdrop
//
//  Created by Logan Moore on 2022-01-08.
//

import Foundation
import SpriteKit

extension DDScene {
  func vivifyBouncyLeaves() {
    let leafAnchors = children
      .filter { child in child.userData?["isLeafAnchor"] as? Bool ?? false }

    for leafAnchor in leafAnchors {
      let leaf = leafAnchor.children.first!

      leafAnchor.physicsBody = SKPhysicsBody()
      leafAnchor.physicsBody?.pinned = true

      leaf.physicsBody!.categoryBitMask = DDBitmask.ground
      leaf.physicsBody!.collisionBitMask = DDBitmask.all ^ DDBitmask.ground

      let leafAnchorScenePosition = leafAnchor.getPosition(within: scene!)
      let leafScenePosition = leaf.getPosition(within: scene!)

      let anchorDistance = leafScenePosition.x - leafAnchorScenePosition.x
      let springOffsetX = 3 * anchorDistance
      let springOffsetY = 2 * abs(anchorDistance)

      let leafAttachPoint = CGPoint(
        x: leafScenePosition.x + anchorDistance,
        y: leafScenePosition.y)

      // TODO(logan): there are some assumptions being made around leaf neutral
      // positions being horizontal. This isn't a terrible idea, but I think in
      // reality it will look better to have the true angles varied a bit. Might
      // never vary enough to actually matter. It'd be worth testing with angled
      // leaves to see what breaks.
      let springJointPrimary = SKPhysicsJointSpring.joint(
        withBodyA: leaf.physicsBody!,
        bodyB: physicsBody!,
        anchorA: leafAttachPoint,
        anchorB: CGPoint(
          x: leafScenePosition.x + springOffsetX,
          y: leafScenePosition.y + springOffsetY))

      let springJointAntirotation = SKPhysicsJointSpring.joint(
        withBodyA: leaf.physicsBody!,
        bodyB: physicsBody!,
        anchorA: leafAttachPoint,
        anchorB: CGPoint(
          x: leafScenePosition.x - springOffsetX,
          y: leafScenePosition.y + springOffsetY))

      let damping = CGFloat(leafAnchor.userData!["damping"] as! Float)
      let frequency = CGFloat(leafAnchor.userData!["frequency"] as! Float)
      springJointPrimary.damping = damping
      springJointPrimary.frequency = frequency
      springJointAntirotation.damping = damping / 2
      springJointAntirotation.frequency = frequency / 2

      let pinJoint = SKPhysicsJointPin.joint(
        withBodyA: leaf.physicsBody!,
        bodyB: physicsBody!,
        anchor: leafAnchorScenePosition)

      physicsWorld.add(pinJoint)
      physicsWorld.add(springJointPrimary)
      physicsWorld.add(springJointAntirotation)
    }
  }

}
