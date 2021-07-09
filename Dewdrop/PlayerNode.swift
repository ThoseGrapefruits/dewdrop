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

  static let ACTION_CHARGE_SHOT = "charge-shot"
  static let GUN_SHAPE = [
    CGPoint(x: 0.0, y:  0.5),
    CGPoint(x: 10.0, y:  2.0),
    CGPoint(x: 16.0, y:  4.0),
    CGPoint(x: 14.0, y: -4.0),
    CGPoint(x: 10.0, y: -2.0),
    CGPoint(x: 0.0, y: -0.5),
  ]
  static let MOVEMENT_FORCE_LIMIT: CGFloat = 3000.0
  static let PLAYER_RADIUS: CGFloat = 15.0
  static let TICK_AIM: TimeInterval = 0.1
  static let TICK_CHARGE_SHOT: TimeInterval = 0.5
  static let TICK_FOLLOW: TimeInterval = 0.1

  let PD_MASS: CGFloat = 0.2
  let PD_RADIUS: CGFloat = 4.2
  let PD_COUNT_INIT = 22
  let PD_COUNT_MAX = 40

  // MARK: State

  var ddScene: Optional<DDScene> = .none
  var joints: [SKNode: Set<SKPhysicsJointSpring>] = [:]
  let mainCircle = SKShapeNode(circleOfRadius: PlayerNode.PLAYER_RADIUS)
  let gun = SKShapeNode(
    points: UnsafeMutablePointer(mutating: PlayerNode.GUN_SHAPE),
    count: PlayerNode.GUN_SHAPE.count)
  let gunJoint = SKNode()
  var wetChildren = Set<SKNode>()

  // MARK: Accessor overrides

  override var position: CGPoint {
    get {
      return mainCircle.position
    }
    set {
      mainCircle.position = newValue
    }
  }

  // MARK: Initialisation

  override init() {
    super.init()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // MARK: protocol SceneAddable

  func addToScene(scene: DDScene) throws {
    guard super.position.equalTo(CGPoint(x: 0, y: 0)) else {
      throw AddToSceneError.notAtOrigin
    }

    scene.addChild(self)
    scene.playerNode = self
    ddScene = scene

    initMainCircle()
    initGun()
    initWetChildren()

    start()
  }

  // MARK: Helpers

  func baptiseWetChild(newChild: SKShapeNode) {
    if wetChildren.contains(newChild) {
      return;
    }

    let physicsBody = SKPhysicsBody(circleOfRadius: PD_RADIUS)

    physicsBody.isDynamic = true
    physicsBody.affectedByGravity = true
    physicsBody.mass = PD_MASS

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

  func initWetChildren() {
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

  func initGun() {
    gunJoint.name = "\(name ?? "unnamed") gun joint"

    gun.name = "\(name ?? "unnamed") gun"
    gun.fillColor = .white
    gun.strokeColor = .green

    gunJoint.addChild(gun)
    gun.position = CGPoint(x: 5, y: 0)
    mainCircle.addChild(gunJoint)
  }

  func initMainCircle() {
    mainCircle.name = "\(name ?? "unnamed") main circle"

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
    trackAim()
  }

  func followFirstTouch() {
    guard let ddScene = ddScene else {
      return
    }

    guard ddScene.moveTouchNode.fingerDown else {
      return run(SKAction.wait(forDuration: PlayerNode.TICK_FOLLOW)) {
        self.followFirstTouch()
      }
    }

    let mainCirclePosition = mainCircle.position
    let touchNodePosition = ddScene.moveTouchNode.position

    let diffX = touchNodePosition.x - mainCirclePosition.x
    let dx = min(
      max(
        diffX * 100,
        -PlayerNode.MOVEMENT_FORCE_LIMIT),
      PlayerNode.MOVEMENT_FORCE_LIMIT)

    let applyForce = SKAction.applyForce(
      CGVector(dx: dx, dy: 0),
      duration: PlayerNode.TICK_FOLLOW)

    mainCircle.run(applyForce) {
      self.followFirstTouch()
    }
  }

  func trackAim() {
    guard let ddScene = ddScene else {
      return
    }

    guard ddScene.aimTouchNode.fingerDown else {
      let action = SKAction.rotate(
        toAngle: -mainCircle.zRotation,
        duration: PlayerNode.TICK_AIM,
        shortestUnitArc: true)
      return gunJoint.run(action) {
        self.trackAim()
      }
    }

    let selfPosition = mainCircle.position
    let targetPosition = ddScene.aimTouchNode.position
    let dY = targetPosition.y - selfPosition.y
    let dX = targetPosition.x - selfPosition.x
    let angle = atan2(dY, dX)

    let action = SKAction.rotate(
      toAngle: angle - mainCircle.zRotation,
      duration: PlayerNode.TICK_AIM,
      shortestUnitArc: true)
    return gunJoint.run(action) {
      self.trackAim()
    }
  }

  // MARK: Combat

  func chamberDroplet() {
    gun.strokeColor = .red
  }

  func fireDroplet() {
    gun.strokeColor = .green
  }
}
