//
//  Player.swift
//  Dewdrop
//
//  Created by Logan Moore on 04.07.2021.
//

import Foundation
import SpriteKit
import SceneKit

enum AddToSceneError: Error {
  /// Player must be added to the scene before being repositioned. The
  /// `wetChildren` do not spawn correctly if the player is anywhere but (0,0).
  case notAtOrigin
}

class DDPlayerNode: SKEffectNode, SKSceneDelegate, DDSceneAddable {
  // MARK: Constants

  static let GUN_SHAPE = [
    CGPoint(x: 0.0, y:  0.5),
    CGPoint(x: 18.0, y:  2.0),
    CGPoint(x: 25.0, y:  4.0),
    CGPoint(x: 23.0, y: -4.0),
    CGPoint(x: 18.0, y: -2.0),
    CGPoint(x: 0.0, y: -0.5),
  ]
  static let MOVEMENT_FORCE_LIMIT: CGFloat = 8000.0
  static let PLAYER_RADIUS: CGFloat = 15.0
  static let TICK_AIM: TimeInterval = 0.1
  static let TICK_CHARGE_SHOT: TimeInterval = 0.5
  static let TICK_FOLLOW: TimeInterval = 0.1

  let PD_MASS: CGFloat = 0.5
  let PD_RADIUS: CGFloat = 4.2
  let PD_COUNT_INIT = 22
  let PD_COUNT_MAX = 40

  // MARK: State

  var ddScene: Optional<DDScene> = .none
  var joints: [SKNode: Set<SKPhysicsJointSpring>] = [:]
  let mainCircle = SKShapeNode(circleOfRadius: DDPlayerNode.PLAYER_RADIUS)
  let gun = DDGun(
    points: UnsafeMutablePointer(mutating: DDPlayerNode.GUN_SHAPE),
    count: DDPlayerNode.GUN_SHAPE.count)
  let gunJoint = SKNode()
  var wetChildren = Set<DDPlayerDroplet>()

  var chamberDropletAction: Optional<SKAction> = .none

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
    guard super.position.equalTo(CGPoint.zero) else {
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

  func baptiseWetChild(newChild: DDPlayerDroplet) {
    if wetChildren.contains(newChild) {
      return;
    }

    let physicsBody = SKPhysicsBody(circleOfRadius: PD_RADIUS)

    physicsBody.isDynamic = true
    physicsBody.affectedByGravity = true
    physicsBody.friction = 0.5
    physicsBody.mass = PD_MASS
    physicsBody.categoryBitMask = DDBitmask.PLAYER_DROPLET

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

  func banishWetChild(wetChild: DDPlayerDroplet) {
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
      let wetChild = DDPlayerDroplet(circleOfRadius: PD_RADIUS)

      wetChild.name = "PD \(name ?? "unnamed") \(i)"

      let angle = CGFloat(i) * CGFloat.pi * 2 / CGFloat(PD_COUNT_INIT)
      let offsetX = cos(angle) * DDPlayerNode.PLAYER_RADIUS
      let offsetY = sin(angle) * DDPlayerNode.PLAYER_RADIUS

      wetChild.position = CGPoint(
        x: mainCircle.position.x + offsetX,
        y: mainCircle.position.y + offsetY)
      wetChild.name = "PD \(i)"

      baptiseWetChild(newChild: wetChild)
    }
  }

  func initGun() {
    gunJoint.name = "\(name ?? "unnamed") gun joint"

    gunJoint.physicsBody = SKPhysicsBody(circleOfRadius: 1)


    gunJoint.physicsBody!.angularDamping = 8
    gunJoint.physicsBody!.pinned = true
    gunJoint.physicsBody!.categoryBitMask = DDBitmask.PLAYER_GUN
    gunJoint.physicsBody!.collisionBitMask = DDBitmask.none

    gun.name = "\(name ?? "unnamed") gun"
    gun.fillColor = .white
    gun.strokeColor = .green

    gun.physicsBody = SKPhysicsBody(
      rectangleOf: CGSize(width: 24.0, height: 4),
      center: CGPoint(x: 12.0, y: 0.0))

    gun.physicsBody!.angularDamping = 8
    gun.physicsBody!.pinned = true
    gun.physicsBody!.allowsRotation = false
    gun.physicsBody!.categoryBitMask = DDBitmask.PLAYER_GUN
    gun.physicsBody!.collisionBitMask = DDBitmask.none

    gunJoint.addChild(gun)
    gun.position = CGPoint(x: 4.0, y: 0.0)
    mainCircle.addChild(gunJoint)
  }

  func initMainCircle() {
    mainCircle.name = "\(name ?? "unnamed") main circle"

    let physicsBody = SKPhysicsBody(circleOfRadius: DDPlayerNode.PLAYER_RADIUS)

    physicsBody.isDynamic = true
    physicsBody.affectedByGravity = false
    physicsBody.mass = 14.0
    physicsBody.categoryBitMask = DDBitmask.PLAYER_DROPLET
    physicsBody.collisionBitMask =
      DDBitmask.all ^ DDBitmask.PLAYER_GUN

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
      return run(SKAction.wait(forDuration: DDPlayerNode.TICK_FOLLOW)) {
        self.followFirstTouch()
      }
    }

    let mainCirclePosition = mainCircle.position
    let touchNodePosition = ddScene.moveTouchNode.position

    let diffX = touchNodePosition.x - mainCirclePosition.x
    let dx = min(
      max(
        diffX * 200,
        -DDPlayerNode.MOVEMENT_FORCE_LIMIT),
      DDPlayerNode.MOVEMENT_FORCE_LIMIT)

    let applyForce = SKAction.applyForce(
      CGVector(dx: dx, dy: 0),
      duration: DDPlayerNode.TICK_FOLLOW)

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
        duration: DDPlayerNode.TICK_AIM,
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
      // TODO: this angle isn't right
      toAngle: angle - mainCircle.zRotation,
      duration: DDPlayerNode.TICK_AIM,
      shortestUnitArc: true)
    return gunJoint.run(action) {
      self.trackAim()
    }
  }

  // MARK: Combat

  func chamberDroplet() {
    let closest: Optional<DDPlayerDroplet> =
      wetChildren.reduce(.none) { closestChild, child in
        guard let closestChild = closestChild else {
          return child;
        }

        let closestDistance = getDistance(gun.position, closestChild.position)
        let distance =        getDistance(gun.position, child.position)
        return distance < closestDistance
          ? child
          : closestChild
      }

    guard let closest = closest else {
      return
    }

    banishWetChild(wetChild: closest)
    gun.chamberDroplet(closest)
  }

  func fireDroplet() {
    gun.fireDroplet()
  }

  // MARK: Utility

  func getDistance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    return sqrt(pow(p2.x - p1.x, 2.0) + pow(p2.y - p2.y, 2.0))
  }
}
