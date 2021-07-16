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

  static let AIM_OFFSET: CGFloat = 20.0
  static let TOUCH_FORCE_JUMP: CGFloat = 3.5
  static let MOVEMENT_FORCE_LIMIT: CGVector = CGVector(dx: 16000.0, dy: 4000.0)
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
    points: &GUN_SHAPE,
    count: DDPlayerNode.GUN_SHAPE.count)
  let gunJoint = SKNode()
  var wetChildren = Set<DDPlayerDroplet>()

  var chamberDropletAction: Optional<SKAction> = .none

  // MARK: Initialisation

  override init() {
    super.init()
    name = "Player"
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    name = "Player"
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



  // MARK: Helpers

  func baptiseWetChild(newChild: DDPlayerDroplet, resetPosition: Bool = false) {
    if wetChildren.contains(newChild) {
      return;
    }

    newChild.onCatch(by: self)

    if newChild.physicsBody == nil {
      newChild.physicsBody = SKPhysicsBody(circleOfRadius: PD_RADIUS)

      newChild.physicsBody!.linearDamping = 3
      newChild.physicsBody!.isDynamic = true
      newChild.physicsBody!.affectedByGravity = true
      newChild.physicsBody!.friction = 0.5
      newChild.physicsBody!.mass = PD_MASS
      newChild.physicsBody!.categoryBitMask = DDBitmask.PLAYER_DROPLET
      newChild.physicsBody!.collisionBitMask =
        DDBitmask.all ^ DDBitmask.PLAYER_GUN
      newChild.physicsBody!.contactTestBitMask = DDBitmask.PLAYER_DROPLET
    }

    if newChild.parent != nil {
      let childPosition = newChild.getPosition(within: scene!)
      let mainCirclePosition = mainCircle.getPosition(within: scene!)
      let angle = mainCirclePosition.angle(to: childPosition)

      newChild.removeFromParent()

      addChild(newChild)

      // Fake initial position to set the joint in the right place
      newChild.position = CGPoint(
        x: mainCircle.position.x + cos(angle) * DDPlayerNode.PLAYER_RADIUS,
        y: mainCircle.position.y + sin(angle) * DDPlayerNode.PLAYER_RADIUS)

      linkArms(wetChild: newChild)

      // Previous position, so it can be pulled in by the joint. We assume that
      // the actual DDPlayerNode is still at (0,0) [invariant]
      newChild.position = childPosition
    } else {
      addChild(newChild)
      linkArms(wetChild: newChild)
    }

    wetChildren.insert(newChild)
    updateGunPosition()
  }

  func banishWetChild(wetChild: DDPlayerDroplet) {
    guard wetChildren.remove(wetChild) != nil else {
      return
    }

    updateGunPosition()

    guard let jointsForWetChild = joints.removeValue(forKey: wetChild) else {
      return
    }

    for joint in jointsForWetChild {
      let otherNode = joint.bodyA.node == self
      ? joint.bodyB.node!
      : joint.bodyA.node!

      joints[otherNode]?.remove(joint)

      scene!.physicsWorld.remove(joint)
    }
  }

  func linkArms(wetChild: DDPlayerDroplet) {
    let joint = SKPhysicsJointSpring.joint(
      withBodyA: mainCircle.physicsBody!,
      bodyB: wetChild.physicsBody!,
      anchorA: mainCircle.position,
      anchorB: wetChild.position)

    joint.damping = 1.5
    joint.frequency = 4.0

    scene!.physicsWorld.add(joint)
  }

  func updateGunPosition() {
    gun.position = CGPoint(x: CGFloat(wetChildren.count) / 2.0, y: 0)
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
    let diffY = touchNodePosition.y - mainCirclePosition.y
    let applyForce = SKAction.applyForce(
      CGVector(
        dx: (diffX * 800).clamp(within: DDPlayerNode.MOVEMENT_FORCE_LIMIT.dx),
        dy: (diffY * 400).clamp(within: DDPlayerNode.MOVEMENT_FORCE_LIMIT.dy)),
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
        let selfPosition =
          mainCircle.position
        let targetPosition = CGPoint(
          x: ddScene.aimTouchNode.position.x,
          y: ddScene.aimTouchNode.position.y + DDPlayerNode.AIM_OFFSET)
        return selfPosition.angle(to: targetPosition)
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
  var holdingJump = false

  func updateTouchForce(_ force: CGFloat) {
    let cravesJump = force > DDPlayerNode.TOUCH_FORCE_JUMP
    guard holdingJump != cravesJump else {
      return
    }

    holdingJump = !holdingJump

    guard cravesJump else {
      return
    }

    let touchingGround = wetChildren
      .compactMap { wetChild in wetChild.physicsBody }
      .flatMap { wetBody in wetBody.allContactedBodies() }
      .map { wetContact in wetContact.categoryBitMask }
      .contains(DDBitmask.GROUND)

    if touchingGround {
      jumpsSinceLastGroundTouch = 0
    }

    if jumpsSinceLastGroundTouch < 2 {
      jumpsSinceLastGroundTouch += 1
      mainCircle.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 800))
      for wetChild in wetChildren {
        wetChild.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 600))
      }
    }
  }

  // MARK: Combat

  func chamberDroplet() {
    let closest: Optional<(DDPlayerDroplet, CGFloat)> =
      wetChildren.reduce(.none) { closest, child in
        guard let (_, closestDistance) = closest else {
          return (child, CGFloat.infinity);
        }

        let positionOfGun = gun.getPosition(within: self)
        let positionOfChild = child.getPosition(within: self)
        let distance =        positionOfGun.distance(to: positionOfChild)

        return distance < closestDistance
          ? (child, distance)
          : closest
      }

    guard let (closestChild, _) = closest else {
      return
    }

    banishWetChild(wetChild: closestChild)
    gun.chamberDroplet(closestChild)
  }

  func fireDroplet() {
    gun.fireDroplet()
  }
}
