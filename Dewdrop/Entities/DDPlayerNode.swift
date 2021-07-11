//
//  Player.swift
//  Dewdrop
//
//  Created by Logan Moore on 04.07.2021.
//

import Foundation
import SpriteKit
import SceneKit

class DDPlayerNode: SKEffectNode, SKSceneDelegate, DDSceneAddable {
  // MARK: Constants

  static var GUN_SHAPE = [
    CGPoint(x: 0.0, y:  0.5),
    CGPoint(x: 18.0, y:  2.0),
    CGPoint(x: 25.0, y:  4.0),
    CGPoint(x: 23.0, y: -4.0),
    CGPoint(x: 18.0, y: -2.0),
    CGPoint(x: 0.0, y: -0.5),
  ]

  static let TOUCH_FORCE_JUMP: CGFloat = 3.5
  static let MOVEMENT_FORCE_LIMIT: CGFloat = 16000.0
  static let PLAYER_RADIUS: CGFloat = 12.0
  static let TICK_AIM: TimeInterval = 0.05
  static let TICK_CHARGE_SHOT: TimeInterval = 0.5
  static let TICK_FOLLOW: TimeInterval = 0.1

  let GUN_MASS: CGFloat = 2.0
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

  // MARK: Initialisation

  override init() {
    super.init()
    name = "DDPlayerNode"
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    name = "DDPlayerNode"
  }

  // MARK: protocol SceneAddable

  func addToScene(scene: DDScene) {
    scene.addChild(self)
    scene.playerNode = self
    ddScene = scene

    physicsBody = SKPhysicsBody()

    physicsBody!.allowsRotation = false
    physicsBody!.isDynamic = false
    physicsBody!.pinned = true

    initMainCircle()
    initGun()
    initWetChildren()
  }

  // MARK: Helpers

  func baptiseWetChild(newChild: DDPlayerDroplet) {
    if wetChildren.contains(newChild) {
      return;
    }

    newChild.physicsBody = SKPhysicsBody(circleOfRadius: PD_RADIUS)

    newChild.physicsBody!.isDynamic = true
    newChild.physicsBody!.affectedByGravity = true
    newChild.physicsBody!.friction = 0.5
    newChild.physicsBody!.mass = PD_MASS
    newChild.physicsBody!.categoryBitMask = DDBitmask.PLAYER_DROPLET
    newChild.physicsBody!.collisionBitMask = DDBitmask.all ^ DDBitmask.PLAYER_GUN

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

    gunJoint.physicsBody = SKPhysicsBody(circleOfRadius: 10)

    gunJoint.physicsBody!.angularDamping = 200
    gunJoint.physicsBody!.pinned = true
    gunJoint.physicsBody!.mass = 4
    gunJoint.physicsBody!.categoryBitMask = DDBitmask.PLAYER_GUN
    gunJoint.physicsBody!.collisionBitMask = DDBitmask.none

    gun.name = "\(name ?? "unnamed") gun"

    gun.physicsBody = SKPhysicsBody(
      rectangleOf: CGSize(width: 24.0, height: 4),
      center: CGPoint(x: 12.0, y: 0.0))

    gun.physicsBody!.pinned = true
    gun.physicsBody!.allowsRotation = false
    gun.physicsBody!.categoryBitMask = DDBitmask.PLAYER_GUN
    gun.physicsBody!.collisionBitMask = DDBitmask.none
    gun.physicsBody!.mass = GUN_MASS

    gunJoint.addChild(gun)
    gun.position = CGPoint(x: 4.0, y: 0.0)
    mainCircle.addChild(gunJoint)
  }

  func initMainCircle() {
    mainCircle.name = "\(name ?? "unnamed") main circle"
    mainCircle.strokeColor = .clear

    mainCircle.physicsBody = SKPhysicsBody(
      circleOfRadius: DDPlayerNode.PLAYER_RADIUS)

    mainCircle.physicsBody!.angularDamping = 5
    mainCircle.physicsBody!.isDynamic = true
    mainCircle.physicsBody!.affectedByGravity = false
    mainCircle.physicsBody!.mass = 14.0
    mainCircle.physicsBody!.categoryBitMask = DDBitmask.PLAYER_DROPLET
    mainCircle.physicsBody!.collisionBitMask =
      DDBitmask.all ^ DDBitmask.PLAYER_GUN

    addChild(mainCircle)
  }

  func distance(_ p: CGPoint, _ q: CGPoint) -> CGFloat {
    return sqrt(pow(q.x - p.x, 2) + pow(q.y - p.y, 2))
  }

  // MARK: Game loops

  func start() {
    trackMovementTouch()
    trackAimTouch()
  }

  func trackMovementTouch() {
    guard let ddScene = ddScene else {
      return
    }

    guard ddScene.moveTouchNode.fingerDown else {
      return run(SKAction.wait(forDuration: DDPlayerNode.TICK_FOLLOW)) {
        self.trackMovementTouch()
      }
    }

    let mainCirclePosition = mainCircle.position
    let touchNodePosition = ddScene.moveTouchNode.position

    let diffX = touchNodePosition.x - mainCirclePosition.x
    let dx = min(
      max(
        diffX * 800,
        -DDPlayerNode.MOVEMENT_FORCE_LIMIT),
      DDPlayerNode.MOVEMENT_FORCE_LIMIT)

    let applyForce = SKAction.applyForce(
      CGVector(dx: dx, dy: 0),
      duration: DDPlayerNode.TICK_FOLLOW)

    mainCircle.run(applyForce) {
      self.trackMovementTouch()
    }
  }

  func trackAimTouch(
    pid: PIDController = PIDController(kP: 1.0, kI: 0, kD: 0.05)
  ) {
    guard let ddScene = ddScene else {
      return
    }

    let targetAngle: CGFloat = ddScene.aimTouchNode.fingerDown
      ? {
        let selfPosition = mainCircle.position
        let targetPosition = ddScene.aimTouchNode.position
        return atan2(
          targetPosition.y - selfPosition.y,
          targetPosition.x - selfPosition.x)
      }()
      : 0

    let currentAngle = mainCircle.zRotation + gunJoint.zRotation

    let impulse = pid.step(
      error: (targetAngle - currentAngle).wrap(around: CGFloat.pi),
      deltaTime: DDPlayerNode.TICK_AIM)

    let action = SKAction.applyAngularImpulse(
      impulse,
      duration: DDPlayerNode.TICK_AIM)

    return gunJoint.run(action) {
      self.trackAimTouch(pid: pid)
    }
  }

  // MARK: Jumping

  var jumpsSinceLastGroundTouch: Int = 0
  var holdJump = false

  func updateTouchForce(_ force: CGFloat) {
    let cravesJump = force > DDPlayerNode.TOUCH_FORCE_JUMP
    guard holdJump != cravesJump else {
      return
    }

    holdJump = !holdJump

    if cravesJump && jumpsSinceLastGroundTouch < 100000 {
      jumpsSinceLastGroundTouch += 1
      mainCircle.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 800))
      for wetChild in wetChildren {
        wetChild.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 600))
      }
    }
  }

  // MARK: Combat

  func chamberDroplet() {
    let closest: Optional<DDPlayerDroplet> =
      wetChildren.reduce(.none) { closestChild, child in
        guard let closestChild = closestChild else {
          return child;
        }

        let positionOfGun = gun.getPosition(
          withinAncestor: mainCircle)
        let positionOfChild = child.getPosition(
          withinAncestor: mainCircle)
        let positionOfClosestChild = closestChild.getPosition(
          withinAncestor: mainCircle)

        let closestDistance = getDistance(positionOfGun, positionOfClosestChild)
        let distance =        getDistance(positionOfGun, positionOfChild)

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
