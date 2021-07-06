//
//  Player.swift
//  Dewdrop
//
//  Created by Logan Moore on 04.07.2021.
//

import Foundation
import SpriteKit

enum AddToSceneError: Error {
  /// Player must be added to the scene before being repositioned. The
  /// `wetChildren` do not spawn correctly if the player is anywhere but (0,0).
  case notAtOrigin
}

class PlayerNode: SKEffectNode, SKSceneDelegate, SceneAddable {
  // MARK: Constants

  static let PLAYER_RADIUS: CGFloat = 15.0
  static let TICK_FOLLOW: TimeInterval = 0.1

  let PD_RADIUS: CGFloat = 4.2
  let PD_COUNT_INIT = 22
  let PD_COUNT_MAX = 40

  // MARK: State

  let mainCircle = SKShapeNode(circleOfRadius: PlayerNode.PLAYER_RADIUS)
  var wetChildren = Set<SKNode>()
  var joints: [SKNode: Set<SKPhysicsJointSpring>] = [:]

  // MARK: Initialisation

  override init() {
    super.init()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // MARK: protocol SceneAddable

  func addToScene(scene: SKScene) throws {
    guard position.equalTo(CGPoint(x: 0, y: 0)) else {
      throw AddToSceneError.notAtOrigin
    }

    scene.addChild(self)
    initMainCircle()
    initChildren()
  }

  // MARK: Helpers

  func baptiseWetChild(newChild: SKShapeNode) {
    if wetChildren.contains(newChild) {
      return;
    }

    let physicsBody = SKPhysicsBody(circleOfRadius: PD_RADIUS)

    physicsBody.isDynamic = true
    physicsBody.affectedByGravity = true
    physicsBody.mass = 2 / CGFloat(PD_COUNT_INIT)

    newChild.physicsBody = physicsBody

    addChild(newChild)

    let joint = SKPhysicsJointSpring.joint(
      withBodyA: mainCircle.physicsBody!,
      bodyB: newChild.physicsBody!,
      anchorA: mainCircle.position,
      anchorB: newChild.position)

    joint.damping = 1.5
    joint.frequency = 4.0

    scene!.physicsWorld.add(joint)

    wetChildren.insert(newChild)
  }

  func banishWetChild(wetChild: SKShapeNode) {
    if wetChildren.remove(wetChild) != nil {
      if let jointsForWetChild = joints.removeValue(forKey: wetChild) {
        for joint in jointsForWetChild {
          let otherNode = joint.bodyA.node == self
            ? joint.bodyB.node!
            : joint.bodyA.node!

          joints[otherNode]?.remove(joint)

          scene!.physicsWorld.remove(joint)
        }
      }
    }
  }

  func initChildren() {
    for i in 0..<PD_COUNT_INIT {
      let wetChild = SKShapeNode(circleOfRadius: PD_RADIUS)

      wetChild.name = "PD \(name ?? "unnamed") \(i)"

      let angle = CGFloat(i) * CGFloat.pi * 2 / CGFloat(PD_COUNT_INIT)
      let offsetX = cos(angle) * PlayerNode.PLAYER_RADIUS
      let offsetY = sin(angle) * PlayerNode.PLAYER_RADIUS

      wetChild.position = CGPoint(
        x: mainCircle.position.x + offsetX,
        y: mainCircle.position.y + offsetY)
      wetChild.name = "PD \(i)"

      baptiseWetChild(newChild: wetChild)
    }
  }

  func initMainCircle() {
    mainCircle.name = name

    let physicsBody = SKPhysicsBody(circleOfRadius: PlayerNode.PLAYER_RADIUS)

    physicsBody.isDynamic = true
    physicsBody.affectedByGravity = false
    physicsBody.mass = 4.0

    mainCircle.physicsBody = physicsBody

    addChild(mainCircle)
  }

  func distance(_ p: CGPoint, _ q: CGPoint) -> CGFloat {
    return sqrt(pow(q.x - p.x, 2) + pow(q.y - p.y, 2))
  }

  // MARK: Game loops

  func start() {
    followFirstTouch()
  }

  func followFirstTouch() {
    
    SKAction.wait(forDuration: PlayerNode.TICK_FOLLOW)
  }
}
