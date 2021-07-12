//
//  DDCamera.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-12.
//

import Foundation
import SpriteKit

class DDCameraNode : SKCameraNode {
  static let TICK_TRACKING: CGFloat = 0.1

  // MARK: Initialisation

  override init() {
    super.init()
    initPhysics()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    initPhysics()
  }

  func initPhysics() {
    physicsBody = SKPhysicsBody()
    physicsBody!.mass = 3.0
    physicsBody!.affectedByGravity = false
    physicsBody!.allowsRotation = false
    physicsBody!.linearDamping = 3
  }

  // MARK: Game loops

  func track(_ node: SKNode,
             pidX: PIDController = PIDController(kP: 4, kI: 0, kD: 2),
             pidY: PIDController = PIDController(kP: 4, kI: 0, kD: 2)) {
    guard let scene = scene else {
      return
    }

    let cameraScenePosition = self.getPosition(within: scene)
    let nodeScenePosition =   node.getPosition(within: scene)
    let errorX = nodeScenePosition.x - cameraScenePosition.x
    let errorY = nodeScenePosition.y - cameraScenePosition.y

    let force = SKAction.applyForce(
      CGVector(
        dx: pidX.step(error: errorX, deltaTime: DDCameraNode.TICK_TRACKING),
        dy: pidY.step(error: errorY, deltaTime: DDCameraNode.TICK_TRACKING)),
      duration: DDCameraNode.TICK_TRACKING)

    run(force) {
      self.track(node, pidX: pidX, pidY: pidY)
    }
  }
}
