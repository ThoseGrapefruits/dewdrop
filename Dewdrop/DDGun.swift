//
//  DDGun.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit

class DDGun : SKShapeNode {
  static let LAUNCH_FORCE: CGFloat = 10.0

  var chambered: Optional<DDPlayerDroplet> = .none

  func chamberDroplet(_ droplet: DDPlayerDroplet) {
    chambered = droplet
    strokeColor = .white

    droplet.removeFromParent()
    addChild(droplet)

    let prepareRound = SKAction.move(
      to: CGPoint(x: 0.0, y: 0.0),
      duration: 0.02)
    let chamberRound = SKAction.move(
      to: CGPoint(x: 16.0, y: 0.0),
      duration: 0.08)

    droplet.run(prepareRound) {
      droplet.run(chamberRound) {
        droplet.physicsBody?.pinned = true
        droplet.position = CGPoint(x: 24.0, y: 0.0)
      }
    }
  }

  func fireDroplet() {
    guard let chambered = chambered else {
      return
    }

    strokeColor = .green

    let scenePosition = getScenePosition(ofNode: chambered)

    // Reparent to scene but keep scene-relative position
    chambered.removeFromParent()
    scene?.addChild(chambered)
    chambered.position = scenePosition

    // Apply launch force
    chambered.physicsBody?.pinned = false
    chambered.physicsBody?.applyForce(CGVector(dx: DDGun.LAUNCH_FORCE, dy: 0))
  }

  // MARK: Utilities

  func getScenePosition(ofNode node: SKNode) -> CGPoint {
    var child: Optional<SKNode> = node
    var scenePosition = node.position

    // TODO: this isn't quite right
    while let c = child, let parent = c.parent, c != scene {
      scenePosition = CGPoint(
        x: scenePosition.x
           + cos(-parent.zRotation) * c.position.x
           - sin(-parent.zRotation) * c.position.y,
        y: scenePosition.y
           + sin(-parent.zRotation) * c.position.x
           + cos(-parent.zRotation) * c.position.y)
      child = parent
    }

    return scenePosition
  }
}
