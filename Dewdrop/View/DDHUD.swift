//
//  DDHUD.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-09-23.
//

import Foundation
import SpriteKit

class DDHUD: SKNode, DDSceneAddable {
  // MARK: Constants
  let TICK_TRACKING: CGFloat = 0.1

  // MARK: Child references
  let cameraNode = DDCameraNode()
  let statsNode = DDNetworkStatsNode()

  // MARK: DDSceneAddable & initialisation
  func addToScene(scene: DDScene, position: CGPoint?) {
    move(toParent: scene)

    if let position = position {
      self.position = position
    }

    addChild(cameraNode)
    addChild(statsNode)

    cameraNode.physicsBody = SKPhysicsBody()
    cameraNode.physicsBody!.pinned = true
    cameraNode.physicsBody!.affectedByGravity = false

    statsNode.physicsBody = SKPhysicsBody()
    statsNode.physicsBody!.pinned = true
    statsNode.physicsBody!.affectedByGravity = false

    initPhysics()
    let cameraNode = DDCameraNode()
    scene.camera = cameraNode

    statsNode.tracker = DDNetworkMatch.singleton.networkActivityTracker
    statsNode.start()
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
        dx: pidX.step(error: errorX, deltaTime: TICK_TRACKING),
        dy: pidY.step(error: errorY, deltaTime: TICK_TRACKING)),
      duration: TICK_TRACKING)

    run(force) { [weak self] in
      self?.track(node, pidX: pidX, pidY: pidY)
    }
  }
}
