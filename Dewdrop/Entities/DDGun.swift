//
//  DDGun.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit

class DDGun : SKShapeNode {
  static let LAUNCH_FORCE: CGFloat = 400.0
  static let LAUNCH_MAX_ERROR: CGFloat = CGFloat.pi / 6

  let aimPID = PIDController(kP: 1.0, kI: 0, kD: 0.05)

  // MARK: Audio nodes

  let audioChamber = DDAudioNodeGroup()
    .add(fileNamed: "FSChamberDroplet.aif")
  let audioLaunch = DDAudioNodeGroup()
    .add(fileNamed: "FSLaunchDroplet.aif")

  // MARK: State

  var chambered: Optional<DDPlayerDroplet> = .none
  var chamberedCollisionBitmask: UInt32 = UInt32.zero
  var chamberedCategoryBitmask: UInt32 = UInt32.zero
  var cravesLaunch = false
  var lastLaunchTarget: Optional<CGPoint> = .none
  var playerNode: Optional<DDPlayerNode> = .none

  // MARK: Initialisation

  override init() {
    super.init()
    initColor()
    initAudio()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    initColor()
    initAudio()
  }

  func initAudio() {
    addChild(audioChamber)
    addChild(audioLaunch)
  }

  func initColor() {
    fillColor = .systemGreen
    strokeColor = .green
  }

  func start(playerNode: DDPlayerNode) {
    self.playerNode = playerNode
    trackAimTouch();
  }

  // MARK: Actions

  func chamberDroplet(_ droplet: DDPlayerDroplet) {
    guard chambered == nil else {
      return
    }

    chambered = droplet
    strokeColor = .white

    if let dropletPhysicsBody = droplet.physicsBody {
      chamberedCategoryBitmask = dropletPhysicsBody.categoryBitMask
      chamberedCollisionBitmask = dropletPhysicsBody.collisionBitMask

      dropletPhysicsBody.categoryBitMask = DDBitmask.NONE
      dropletPhysicsBody.collisionBitMask = DDBitmask.NONE
    }

    droplet.removeFromParent()
    addChild(droplet)

    droplet.physicsBody?.pinned = true
    droplet.position = CGPoint(x: 24.0, y: 0.0)

    audioChamber.playRandom()
  }

  func launchDroplet() {
    guard let chambered = chambered else {
      return
    }

    lastLaunchTarget = playerNode?.ddScene?.aimTouchNode.position

    guard abs(aimPID.lastError) < DDGun.LAUNCH_MAX_ERROR else {
      cravesLaunch = true
      return
    }

    cravesLaunch = false

    strokeColor = .green

    let scenePosition = chambered.getPosition(within: scene!)

    // Reparent to scene but keep scene-relative position
    chambered.removeFromParent()
    chambered.onRelease()
    scene?.addChild(chambered)
    chambered.position = scenePosition

    guard let chamberedPhysicsBody = chambered.physicsBody else {
      return
    }

    // Reset the physics bitmasks
    if chamberedCollisionBitmask != UInt32.zero {
      chamberedPhysicsBody.collisionBitMask = chamberedCollisionBitmask
    }

    if (chamberedCategoryBitmask != UInt32.zero) {
      chamberedPhysicsBody.categoryBitMask = chamberedCategoryBitmask
    }

    chamberedCategoryBitmask = UInt32.zero
    chamberedCollisionBitmask = UInt32.zero

    let launchAngle = getRotation(within: scene!)
    chamberedPhysicsBody.pinned = false
    chamberedPhysicsBody.applyImpulse(CGVector(
      dx: cos(launchAngle) * DDGun.LAUNCH_FORCE,
      dy: sin(launchAngle) * DDGun.LAUNCH_FORCE))

    self.chambered = .none

    audioLaunch.playRandom()
  }

  // MARK: Game loops

  func trackAimTouch() {
    guard let playerNode = playerNode,
          let gunAnchor = parent else {
      return
    }

    let shouldLaunch = cravesLaunch &&
      abs(aimPID.lastError) < DDGun.LAUNCH_MAX_ERROR

    if shouldLaunch {
      launchDroplet()
    }

    let currentAngle = playerNode.mainCircle.zRotation + gunAnchor.zRotation
    let targetAngle = getAimTargetAngle()

    let impulse = aimPID.step(
      error: (targetAngle - currentAngle).wrap(around: CGFloat.pi),
      deltaTime: DDPlayerNode.TICK_AIM)

    let action = SKAction.applyAngularImpulse(
      impulse,
      duration: DDPlayerNode.TICK_AIM)

    return gunAnchor.run(action) { [weak self] in
      self?.trackAimTouch()
    }
  }

  // MARK: Util

  func getAimTargetAngle() -> CGFloat {
    guard let playerNode = playerNode,
          let ddScene = playerNode.ddScene else {
      return 0
    }

    let targetPosition = ddScene.aimTouchNode.fingerDown
      ? ddScene.aimTouchNode.position
      : cravesLaunch ? lastLaunchTarget : nil

    guard let targetPosition = targetPosition else {
      return 0
    }

    let selfPosition = playerNode.mainCircle.position
    let targetPositionOffset = CGPoint(
      x: targetPosition.x,
      y: targetPosition.y + DDPlayerNode.AIM_OFFSET)
    return selfPosition.angle(to: targetPositionOffset)
  }
}
