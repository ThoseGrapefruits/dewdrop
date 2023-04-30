//
//  Player.swift
//  Dewdrop
//
//  Created by Logan Moore on 04.07.2021.
//

import Foundation
import SpriteKit
import SceneKit
import GameController

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

  // MARK: Child nodes

  let gun = DDGun(
    points: &GUN_SHAPE,
    count: DDPlayerNode.GUN_SHAPE.count)
  let gunAnchor = SKNode()
  let mainCircle = SKShapeNode(circleOfRadius: DDPlayerNode.PLAYER_RADIUS)

  // MARK: State

  var ddScene: Optional<DDScene> = .none
  var joints: [SKNode: Set<SKPhysicsJointSpring>] = [:]
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
  func addToScene(scene: DDScene) -> Self {
    return addToScene(scene: scene, position: .none)
  }

  func addToScene(scene: DDScene, position: CGPoint? = .none) -> Self {
    scene.addChild(self)
    ddScene = scene

    physicsBody = SKPhysicsBody()

    physicsBody!.allowsRotation = false
    physicsBody!.isDynamic = false
    physicsBody!.pinned = true

    initMainCircle(position: position)
    initGun()
    initWetChildren()
    
    return self
  }

  func initWetChildren() {
    for i in 0..<PD_COUNT_INIT {
      let wetChild = DDPlayerDroplet(circleOfRadius: PD_RADIUS)

      let angle = CGFloat(i) * CGFloat.pi * 2 / CGFloat(PD_COUNT_INIT)
      let offsetX = cos(angle) * DDPlayerNode.PLAYER_RADIUS
      let offsetY = sin(angle) * DDPlayerNode.PLAYER_RADIUS

      wetChild.name = "PD \(i)"

      baptiseWetChild(newChild: wetChild, position: CGPoint(
        x: mainCircle.position.x + offsetX,
        y: mainCircle.position.y + offsetY)
      )
    }
  }

  func initGun() {
    gunAnchor.name = "\(name ?? "unnamed") gun joint"

    gunAnchor.physicsBody = SKPhysicsBody(circleOfRadius: 10)

    gunAnchor.physicsBody!.angularDamping = 200
    gunAnchor.physicsBody!.pinned = true
    gunAnchor.physicsBody!.mass = 4
    gunAnchor.physicsBody!.categoryBitMask = DDBitmask.playerGun
    gunAnchor.physicsBody!.collisionBitMask = DDBitmask.NONE

    gun.name = "\(name ?? "unnamed") gun"

    gun.physicsBody = SKPhysicsBody(
      rectangleOf: CGSize(width: 24.0, height: 4),
      center: CGPoint(x: 12.0, y: 0.0))

    gun.physicsBody!.pinned = true
    gun.physicsBody!.allowsRotation = false
    gun.physicsBody!.categoryBitMask = DDBitmask.playerGun
    gun.physicsBody!.collisionBitMask = DDBitmask.NONE
    gun.physicsBody!.mass = GUN_MASS

    gunAnchor.addChild(gun)
    mainCircle.addChild(gunAnchor)
  }

  func initMainCircle(position: CGPoint? = .none) {
    mainCircle.name = "\(name ?? "unnamed") main circle"
    mainCircle.strokeColor = .blue

    mainCircle.physicsBody = SKPhysicsBody(
      circleOfRadius: DDPlayerNode.PLAYER_RADIUS)

    mainCircle.physicsBody!.angularDamping = 5
    mainCircle.physicsBody!.isDynamic = true
    mainCircle.physicsBody!.affectedByGravity = false
    mainCircle.physicsBody!.mass = 14.0
    mainCircle.physicsBody!.categoryBitMask = DDBitmask.playerDroplet
    mainCircle.physicsBody!.collisionBitMask =
      DDBitmask.ALL ^ DDBitmask.playerGun

    addChild(mainCircle)

    if let position = position {
      mainCircle.position = position
    }
  }

  // MARK: Helpers

  func baptiseWetChild(newChild: DDPlayerDroplet, position: CGPoint? = .none) {
    if wetChildren.contains(newChild) {
      return;
    }

    newChild.onCatch(by: self)

    if newChild.physicsBody == nil {
      newChild.physicsBody = SKPhysicsBody(circleOfRadius: PD_RADIUS)

      newChild.physicsBody!.linearDamping = 1
      newChild.physicsBody!.isDynamic = true
      newChild.physicsBody!.affectedByGravity = true
      newChild.physicsBody!.friction = 0.5
      newChild.physicsBody!.mass = PD_MASS
      newChild.physicsBody!.categoryBitMask = DDBitmask.playerDroplet
      newChild.physicsBody!.collisionBitMask =
        DDBitmask.ALL ^ DDBitmask.playerGun
      newChild.physicsBody!.contactTestBitMask = DDBitmask.playerDroplet
    }

    if newChild.parent == nil {
      addChild(newChild)

      if let position = position {
        newChild.position = position
      }

      linkArms(wetChild: newChild)
    } else {
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
    if controller != nil {
      self.setupControllerListeners()
      self.trackInputController()
    } else {
      trackInputTouch()
    }
    gun.start(playerNode: self)
  }

  private func trackInputTouch() {
    guard let ddScene = ddScene else {
      return
    }

    guard ddScene.moveTouchNode.fingerDown else {
      let wait = SKAction.wait(forDuration: DDPlayerNode.TICK_FOLLOW)
      return run(wait) { [weak self] in
        self?.trackInputTouch()
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

    mainCircle.run(applyForce) { [weak self] in
      self?.trackInputTouch()
    }
  }
  
  // MARK: Controller handling
  
  var controller: GCController?;
  
  func set(controller: GCController) -> Self {
    self.controller = controller;
    
    return self;
  }
  
  func setupControllerListeners() {
    guard let controller = controller else {
      return
    }

    if let gamepad = controller.microGamepad {
      gamepad.allowsRotation = true;
      print("--gamepad-- micro \(gamepad.dpad.description) \( gamepad.allTouchpads )")

      // D-pad movement
      gamepad.dpad.valueChangedHandler = { dpad, xValue, yValue in
          print("--button-- DPad \(xValue) \(yValue)")
        // TODO
      }
      
      // D-Pad press
      gamepad.buttonA.valueChangedHandler = { button, _, pressed in
        print("--button-- A \(pressed)")
        // TODO
      }
      
      // Play/Pause button
      gamepad.buttonX.valueChangedHandler = { button, _, pressed in
        print("--button-- X \(pressed)")
        self.set(cravesJump: pressed)
      }
      
      // Menu button
      gamepad.buttonMenu.valueChangedHandler = { button, _, pressed in
        print("--button-- Menu \(pressed)")
        guard let scene = self.scene, pressed else {
          return
        }

        scene.isPaused = !scene.isPaused
      }
    } else if let gamepad = controller.extendedGamepad {
      print("--gamepad-- macro")
      gamepad.buttonA.valueChangedHandler = { button, _, pressed in
        self.set(cravesJump: pressed)
      }
      gamepad.buttonMenu.valueChangedHandler = { button, _, pressed in
        // TODO pause
      }
    }
  }
  
  func trackInputController() {
    guard let controller = controller else {
      return
    }
    
    var x: Float?;
    var y: Float?;

    if let gamepad = controller.extendedGamepad {
      x = gamepad.leftThumbstick.xAxis.value;
      y = gamepad.leftThumbstick.yAxis.value;
    } else if let gamepad = controller.microGamepad {
      x = gamepad.dpad.xAxis.value
      y = gamepad.dpad.yAxis.value
    }

    guard let x = x, let y = y, y != 0, x != 0 else {
      let wait = SKAction.wait(forDuration: DDPlayerNode.TICK_FOLLOW)
      return run(wait) { [weak self] in
        self?.trackInputController()
      }
    }

    let applyForce = SKAction.applyForce(
      CGVector(
        dx: (CGFloat(x) * 20_000).clamp(within: DDPlayerNode.MOVEMENT_FORCE_LIMIT.dx),
        dy: (CGFloat(y) * 6_000).clamp(within: DDPlayerNode.MOVEMENT_FORCE_LIMIT.dy)),
      duration: DDPlayerNode.TICK_FOLLOW)

    mainCircle.run(applyForce) { [weak self] in
      self?.trackInputController()
    }
  }

  // MARK: Jumping

  var jumpsSinceLastGroundTouch: Int8 = 0
  var holdingJump = false
  
  func handleTouch(force: CGFloat) {
    set(cravesJump: force > DDPlayerNode.TOUCH_FORCE_JUMP)
  }

  func set(cravesJump: Bool) {
    guard holdingJump != cravesJump else {
      return
    }

    holdingJump = cravesJump

    guard cravesJump else {
      return
    }

    let groundContacts = wetChildren
      .compactMap { wetChild in wetChild.physicsBody }
      .flatMap { wetBody in wetBody.allContactedBodies() }
      .filter { contactBody in contactBody.categoryBitMask == DDBitmask.ground }
      .reduce(into: [SKPhysicsBody: Int]()) { counts, groundBody in
        counts[groundBody] = (counts[groundBody] ?? 0) + 1
      }

    if groundContacts.count != 0 {
      jumpsSinceLastGroundTouch = 0

      let totalContact =
        groundContacts.values.reduce(0) { sum, count in sum + count }
      let positionInScene = mainCircle.getPosition(within: scene!)

      for (body, contactCount) in groundContacts {
        let fractionOfTotal = contactCount / totalContact
        body.applyImpulse(
          CGVector(dx: 0, dy: 1600 * fractionOfTotal),
          at: positionInScene)
      }
    }

    guard jumpsSinceLastGroundTouch < 2 else {
      return
    }

    jumpsSinceLastGroundTouch += 1
    mainCircle.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 800))
    for wetChild in wetChildren {
      wetChild.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 600))
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

  func launchDroplet() {
    gun.launchDroplet()
  }
}
