//
//  DDGun.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit

class DDGun : SKShapeNode {
  func chamberDroplet(_ droplet: DDPlayerDroplet) {
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
        droplet.position = CGPoint(x: 16.0, y: 0.0)
      }
    }
  }
}
