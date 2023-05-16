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

  static let AIM_OFFSET: CGFloat       =    20.0
  static let DETACH_DISTANCE: CGFloat  =   50.0;
  static let TOUCH_FORCE_JUMP: CGFloat =     3.5
  static let JUMP_SCALE: CGFloat       = 2_000.0;
  static let PLAYER_RADIUS: CGFloat    =    12.0
  
  static let MOVEMENT_SPEED_LIMIT: CGVector = CGVector(dx:   500.0, dy: 1000.0)

  static let WAIT_AIM         = SKAction.wait(forDuration: 0.05)
  static let WAIT_CHARGE_SHOT = SKAction.wait(forDuration: 0.5)
  static let WAIT_FOLLOW      = SKAction.wait(forDuration: 0.1)
  static let WAIT_CHECK       = SKAction.wait(forDuration: 0.5)

  let GUN_MASS: CGFloat = 2.0
  let PD_COUNT_INIT = 22
  let PD_COUNT_MAX = 40

  // MARK: Child nodes

  let gun = DDGun(
    points: &GUN_SHAPE,
    count: GUN_SHAPE.count)
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

    #if !os(iOS)
    ddScene!.playerNodes.append(self)
    #endif

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
      let wetChild = DDPlayerDroplet(circleOfRadius: DDPlayerDroplet.RADIUS)

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

    mainCircle.physicsBody!.angularDamping = 3
    mainCircle.physicsBody!.isDynamic = true
    mainCircle.physicsBody!.affectedByGravity = false
    mainCircle.physicsBody!.linearDamping = 0.8
    mainCircle.physicsBody!.mass = 14.0
    mainCircle.physicsBody!.categoryBitMask = DDBitmask.playerDroplet
    mainCircle.physicsBody!.collisionBitMask =
      DDBitmask.ALL ^ DDBitmask.playerGun ^ DDBitmask.playerDroplet

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
    newChild.initPhysics()

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

  func disown(wetChild: DDPlayerDroplet) {
    guard wetChild.lock == .none else {
      return
    }
    
    wetChild.lock = .banishing
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
      joints[mainCircle]?.remove(joint)

      scene!.physicsWorld.remove(joint)
    }
    
    wetChild.lock = .none
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
    
    joints[mainCircle] = joints[mainCircle] ?? Set();
    joints[mainCircle]!.insert(joint)
    joints[wetChild] = joints[wetChild] ?? Set()
    joints[wetChild]!.insert(joint)
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
      #if os(iOS)
      trackInputTouch()
      #endif
    }
    
    trackChildren()
    
    gun.start(playerNode: self)
  }
  
  private func trackChildren() {
    for child in wetChildren {
      let distance = mainCircle.position.distance(to: child.position)

      if (distance > DDPlayerNode.DETACH_DISTANCE) {
        print("--child strayed too far-- \(child.lock) \(child)")
        disown(wetChild: child)
        child.onRelease()
        child.removeFromParent()
        scene?.addChild(child)
      }
    }
    
    run(DDPlayerNode.WAIT_CHECK) { [weak self] in
      self?.trackChildren()
    }
  }
  
  // MARK: Touch handling

  #if os(iOS)
  private func trackInputTouch() {
    guard let ddScene = ddScene else {
      return
    }

    guard ddScene.moveTouchNode.fingerDown else {
      return run(DDPlayerNode.WAIT_FOLLOW) { [weak self] in
        self?.trackInputTouch()
      }
    }

    let mainCirclePosition = mainCircle.position
    let touchNodePosition = ddScene.moveTouchNode.position

    let diffX = touchNodePosition.x - mainCirclePosition.x
    let diffY = touchNodePosition.y - mainCirclePosition.y

    let force = CGVector(
      dx: (diffX * 800)
        .clamp(within: DDPlayerNode.MOVEMENT_FORCE_LIMIT.dx)
        .clamp(within: clampX ? 0 : CGFloat.infinity),
      dy: (diffY * 400)
        .clamp(within: DDPlayerNode.MOVEMENT_FORCE_LIMIT.dy))

    applyMovementForce(force) { [weak self] in
      self?.trackInputTouch()
    }
  }
  #endif
  
  // MARK: Controller handling
  
  var controller: GCController?;
  var dpad = GCControllerDirectionPad();
  
  func set(controller: GCController) -> Self {
    self.controller = controller;
    
    return self;
  }
  
  func setupControllerListeners() {
    guard let controller = controller else {
      return
    }
    
    var buttonMenu:  GCControllerButtonInput?;
    var buttonJump:  GCControllerButtonInput?;
    var buttonShoot: GCControllerButtonInput?;

    if let gamepad = controller.extendedGamepad {
      buttonJump = gamepad.buttonA
      buttonShoot = gamepad.rightShoulder
      buttonMenu = gamepad.buttonMenu
      dpad = gamepad.leftThumbstick
    } else if let gamepad = controller.microGamepad {
      gamepad.allowsRotation = true
      
      buttonJump = gamepad.buttonA
      buttonMenu = gamepad.buttonMenu
      buttonShoot = gamepad.buttonX
      dpad = gamepad.dpad
    }
    
    buttonJump?.valueChangedHandler = { [weak self] button, _, pressed in
      self?.set(cravesJump: pressed)
    }
    
    buttonMenu?.valueChangedHandler = { [weak self] button, _, pressed in
      guard pressed, let scene = self?.scene else {
        return
      }

      scene.isPaused = !scene.isPaused
    }
    
    buttonShoot?.valueChangedHandler = { [weak self] button, _, pressed in
      if (pressed) {
        self?.chamberDroplet()
      } else {
        self?.launchDroplet()
      }
    }
  }
  
  func trackInputController() {
    let x = dpad.xAxis.value
    let y = dpad.xAxis.value
    
    guard y != 0, x != 0 else {
      return run(DDPlayerNode.WAIT_FOLLOW) { [weak self] in
        self?.trackInputController()
      }
    }
    
    let sizeScaleFactor = log(CGFloat(wetChildren.count))
    
    print("--size-- \(wetChildren.count) \(sizeScaleFactor)")
    
    let direction = CGVector(
      dx: (CGFloat(x) * 10_000 * sizeScaleFactor),
      dy: (CGFloat(y) * 6_000 * sizeScaleFactor)
    )
    
    applyMovementForce(direction) { [weak self] in
      self?.trackInputController()
    }
  }
  
  // MARK: Movement
  
  func applyMovementForce(
    _ force: CGVector,
    completion block: @escaping () -> Void
  ) {
    guard let physicsBody = mainCircle.physicsBody else {
      return;
    }
    
    let clampX =
    force.dx.sign == physicsBody.velocity.dx.sign &&
    physicsBody.velocity.dx.magnitude > DDPlayerNode.MOVEMENT_SPEED_LIMIT.dx;
    
    let clampY =
    force.dy.sign == physicsBody.velocity.dy.sign &&
    physicsBody.velocity.dy.magnitude > DDPlayerNode.MOVEMENT_SPEED_LIMIT.dy;
    
    let forceClamped = CGVector(
      dx: force.dx.clamp(within: clampX ? 0 : .infinity),
      dy: force.dy.clamp(within: clampY ? 0 : .infinity))
      
    self.mainCircle.run(
      SKAction.applyForce(
        forceClamped,
        duration: DDPlayerNode.WAIT_FOLLOW.duration),
      completion: block)
  }

  // MARK: Jumping

  var jumpsSinceLastGroundTouch: Int8 = 0
  var holdingJump = false
  
  func getGroundContacts() -> [SKPhysicsBody: Int] {
    return wetChildren
      .compactMap { wetChild in wetChild.physicsBody }
      .flatMap { wetBody in wetBody.allContactedBodies() }
      .filter { contactBody in contactBody.categoryBitMask == DDBitmask.ground }
      .reduce(into: [SKPhysicsBody: Int]()) { counts, groundBody in
        counts[groundBody] = (counts[groundBody] ?? 0) + 1
      }
  }
  
  func getGroundContactsTotalCount() -> Int {
    return self.getGroundContactsTotalCount(withContacts: self.getGroundContacts())
  }
  
  func getGroundContactsTotalCount(
    withContacts groundContacts: [SKPhysicsBody: Int]
  ) -> Int {
    groundContacts.values.reduce(0) { sum, n in
      sum + n
    }
  }
  
  func handleCollision(withGround: SKNode) {
    self.resetJumps()
  }
  
  func handleForceTouch(force: CGFloat) {
    set(cravesJump: force > DDPlayerNode.TOUCH_FORCE_JUMP)
  }
  
  func resetJumps() {
    self.resetJumps(withContacts: self.getGroundContacts())
  }
  
  func resetJumps(withContacts groundContacts: [SKPhysicsBody: Int]) {
    guard jumpsSinceLastGroundTouch != 0 else {
      return
    }

    let contactCount = self.getGroundContactsTotalCount(withContacts: groundContacts)

    if contactCount >= 4 {
      jumpsSinceLastGroundTouch = 0
    }
  }

  func set(cravesJump: Bool) {
    guard holdingJump != cravesJump else {
      return
    }

    holdingJump = cravesJump

    guard cravesJump else {
      return
    }
    
    let groundContacts = self.getGroundContacts()
    let totalContactCount = self.getGroundContactsTotalCount(withContacts: groundContacts)
    
    self.resetJumps(withContacts: groundContacts)

    if totalContactCount >= 1 {
      let positionInScene = mainCircle.getPosition(within: scene!)

      for (body, contactCount) in groundContacts {
        let fractionOfTotal: CGFloat = CGFloat(contactCount) / CGFloat(totalContactCount)
        body.applyImpulse(
          CGVector(dx: 0, dy: -30 * DDPlayerNode.JUMP_SCALE * fractionOfTotal),
          at: positionInScene)
      }
    }

    guard jumpsSinceLastGroundTouch < 2 else {
      return
    }

    jumpsSinceLastGroundTouch += 1
    mainCircle.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 1.6 * DDPlayerNode.JUMP_SCALE))
    for wetChild in wetChildren {
      wetChild.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 0.5 * DDPlayerNode.JUMP_SCALE))
    }
  }

  // MARK: Combat

  func chamberDroplet() {
    let closest: Optional<(DDPlayerDroplet, CGFloat)> = wetChildren
      .filter { child in child.lock == .none }
      .reduce(.none) { closest, child in
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

    disown(wetChild: closestChild)
    gun.chamberDroplet(closestChild)
  }

  func launchDroplet() {
    gun.launchDroplet()
  }
}
