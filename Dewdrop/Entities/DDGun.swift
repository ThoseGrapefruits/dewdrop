//
//  DDGun.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit
import GameController

class DDGun : SKShapeNode {
  static let LAUNCH_FORCE: CGFloat = 400.0
  
  // Had these before, but settign them to their max possible value because I
  // don't think they're necessary but I also don't want to remove the logic.
  #if os(iOS)
  static let LAUNCH_MAX_ERROR: CGFloat = CGFloat.pi * 2
  #else
  static let LAUNCH_MAX_ERROR: CGFloat = CGFloat.pi * 2
  #endif

  let aimPID = PIDController(kP: 0.5, kI: 0.02, kD: 0.05)

  // MARK: Audio nodes

  let audioChamber = DDAudioNodeGroup()
    .add(fileNamed: "FSChamberDroplet.aif")
  let audioLaunch = DDAudioNodeGroup()
    .add(fileNamed: "FSLaunchDroplet.aif")

  // MARK: Refs

  weak private(set) var chambered: DDDroplet? = .none
  weak private(set) var playerNode: DDPlayerNode? = .none

  // MARK: State

  var chamberedCollisionBitmask: UInt32 = UInt32.zero
  var chamberedCategoryBitmask: UInt32 = UInt32.zero
  var chamberedMass: CGFloat = CGFloat.zero
  var cravesLaunch = false
  var dpadAim: GCControllerDirectionPad? = .none;
  var lastLaunchTarget: CGPoint? = .none
  var lastTargetAngle: CGFloat = 0

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
    
    if let controller = playerNode.controller {
      if let gamepad = controller.extendedGamepad {
        dpadAim = gamepad.rightThumbstick
      } else if let gamepad = controller.microGamepad {
        dpadAim = gamepad.dpad
      }
    }

    trackAim();
  }

  // MARK: Actions

  func chamberDroplet(_ droplet: DDDroplet) {
    guard chambered == nil else {
      return
    }
    
    droplet.lock = .chambering

    chambered = droplet
    strokeColor = .white

    chamberedCategoryBitmask = droplet.physicsBody!.categoryBitMask
    chamberedCollisionBitmask = droplet.physicsBody!.collisionBitMask
    chamberedMass = droplet.physicsBody!.mass

    droplet.physicsBody!.categoryBitMask = DDBitmask.NONE.rawValue
    droplet.physicsBody!.collisionBitMask = DDBitmask.NONE.rawValue
    droplet.physicsBody!.mass = 0.0000001

    droplet.removeFromParent()
    addChild(droplet)

    droplet.physicsBody!.pinned = true
    droplet.position = CGPoint(x: 24.0, y: 0.0)

    audioChamber.playRandom()
    droplet.lock = .none
  }

  func launchDroplet() {
    guard let chambered = chambered else {
      return
    }

    #if os(iOS)
    lastLaunchTarget = playerNode?.ddScene?.aimTouchNode.position
    #endif
    
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
    scene!.addChild(chambered)
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

    if chamberedMass != CGFloat.zero {
      chamberedPhysicsBody.mass = chamberedMass
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

  func trackAim() {
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
    let targetAngle = getAimTargetAngle() ?? lastTargetAngle;
    lastTargetAngle = targetAngle;

    let impulse = aimPID.step(
      error: (targetAngle - currentAngle).wrap(around: CGFloat.pi),
      deltaTime: DDPlayerNode.WAIT_AIM.duration)

    let action = SKAction.applyAngularImpulse(
      impulse,
      duration: DDPlayerNode.WAIT_AIM.duration)

    return gunAnchor.run(action) { [weak self] in
      self?.trackAim()
    }
  }

  // MARK: Util

  func getAimTargetAngle() -> CGFloat? {
    guard let playerNode = playerNode,
          let ddScene = playerNode.ddScene else {
      return .none
    }

    if let joystick = dpadAim {
      return CGFloat(atan2(joystick.yAxis.value, joystick.xAxis.value))
    }
    
    #if os(iOS)
    let targetPosition = ddScene.aimTouchNode.fingerDown
      ? ddScene.aimTouchNode.position
      : cravesLaunch ? lastLaunchTarget : nil

    guard let targetPosition = targetPosition else {
      return .none
    }

    let selfPosition = playerNode.mainCircle.position

    let targetPositionOffset = CGPoint(
      x: targetPosition.x,
      y: targetPosition.y + DDPlayerNode.AIM_OFFSET)
    return selfPosition.angle(to: targetPositionOffset)
    #else
    return .none
    #endif
  }

  // MARK: SKNode
  
  override var name: String? {
    get { "DDGun of \(playerNode?.name ?? "no player")" }
    set {}
  }
}
