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

  static let AIM_OFFSET: CGFloat           =    20.0
  static let DETACH_DISTANCE: CGFloat      =    50.0
  static let TOUCH_FORCE_JUMP: CGFloat     =     3.5
  static let JUMP_SCALE: CGFloat           = 2_000.0
  static let PLAYER_RADIUS_FACTOR: CGFloat =     0.5
  
  static let MOVEMENT_SPEED_LIMIT: CGVector = CGVector(dx:   500.0, dy: 1000.0)

  static let WAIT_AIM         = SKAction.wait(forDuration: 0.05)
  static let WAIT_CHARGE_SHOT = SKAction.wait(forDuration: 0.5)
  static let WAIT_FOLLOW      = SKAction.wait(forDuration: 0.1)
  static let WAIT_RESIZE      = SKAction.wait(forDuration: 0.1)
  static let WAIT_CHECK       = SKAction.wait(forDuration: 0.3)

  static let GUN_MASS: CGFloat = 1.0
  static let PD_COUNT_INIT = 22
  static let PD_COUNT_MAX = 40
  
  // MARK: SKNode
  
  override var name: String? {
    get { "DDPlayerNode \(controller?.playerIndex.rawValue.description ?? "unknown")" }
    set {}
  }
  
  // MARK: Getters

  func getPlayerRadius(isInit: Bool = false) -> CGFloat {
    let count = CGFloat(isInit ? Self.PD_COUNT_INIT : wetChildren.count)
    return count * Self.PLAYER_RADIUS_FACTOR
  }

  // MARK: Child nodes

  let gun = DDGun(
    points: &GUN_SHAPE,
    count: GUN_SHAPE.count)
  let gunAnchor = SKNode()
  let mainCircle = SKShapeNode(
    circleOfRadius: PLAYER_RADIUS_FACTOR * CGFloat(PD_COUNT_INIT)
  )

  // MARK: State

  var damageLast: CGFloat = CGFloat.zero
  var ddScene: Optional<DDScene> = .none
  var joints: [SKNode: Set<SKPhysicsJointSpring>] = [:]
  var wetChildren = Set<DDDroplet>()

  var chamberDropletAction: Optional<SKAction> = .none

  // MARK: Initialisation

  override init() {
    super.init()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  func initWetChildren(toCount count: Int = DDPlayerNode.PD_COUNT_INIT) {
    for i in wetChildren.count...count {
      let wetChild = DDDroplet(circleOfRadius: DDDroplet.RADIUS)

      let angle = CGFloat(i) * CGFloat.pi * 2 / CGFloat(Self.PD_COUNT_INIT)
      let offsetX = cos(angle) * getPlayerRadius(isInit: true)
      let offsetY = sin(angle) * getPlayerRadius(isInit: true)

      baptiseWetChild(
        newChild: wetChild,
        position: CGPoint(
          x: mainCircle.position.x + offsetX,
          y: mainCircle.position.y + offsetY),
        isInit: true
      )
    }
  }

  func initGun() {   
    gunAnchor.name = "\(name ?? "unnamed") gun joint"

    gunAnchor.physicsBody = SKPhysicsBody(circleOfRadius: 10)

    gunAnchor.physicsBody!.angularDamping = 200
    gunAnchor.physicsBody!.pinned = true
    gunAnchor.physicsBody!.mass = 4
    gunAnchor.physicsBody!.categoryBitMask = DDBitmask.gunPlayer.rawValue
    gunAnchor.physicsBody!.collisionBitMask = DDBitmask.NONE.rawValue

    gun.name = "\(name ?? "unnamed") gun"

    gun.physicsBody = SKPhysicsBody(
      rectangleOf: CGSize(width: 24.0, height: 4),
      center: CGPoint(x: 12.0, y: 0.0))

    gun.physicsBody!.pinned = true
    gun.physicsBody!.allowsRotation = false
    gun.physicsBody!.categoryBitMask = DDBitmask.gunPlayer.rawValue
    gun.physicsBody!.collisionBitMask = DDBitmask.NONE.rawValue
    gun.physicsBody!.mass = Self.GUN_MASS

    gunAnchor.addChild(gun)
    mainCircle.addChild(gunAnchor)
  }

  func initMainCircle(position: CGPoint? = .none) {
    mainCircle.name = "\(name ?? "unnamed") main circle"
    mainCircle.strokeColor = .blue

    mainCircle.physicsBody = SKPhysicsBody(
      circleOfRadius: getPlayerRadius(isInit: true))

    mainCircle.physicsBody!.angularDamping = 3
    mainCircle.physicsBody!.isDynamic = true
    mainCircle.physicsBody!.affectedByGravity = false
    mainCircle.physicsBody!.linearDamping = 0.8
    mainCircle.physicsBody!.mass = 14.0
    mainCircle.physicsBody!.categoryBitMask = DDBitmask.dropletPlayer.rawValue
    mainCircle.physicsBody!.collisionBitMask =
      DDBitmask.GROUND_ANY.rawValue |
      DDBitmask.death.rawValue

    addChild(mainCircle)

    if let position = position {
      mainCircle.position = position
    }
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

    if physicsBody == nil {
      physicsBody = SKPhysicsBody()

      physicsBody!.allowsRotation = false
      physicsBody!.isDynamic = false
      physicsBody!.pinned = true
    }

    initMainCircle(position: position)
    initGun()
    initWetChildren()
    
    return self
  }
  
  func respawn() {
    guard let scene = scene as? DDScene else {
      return
    }
    
    while !wetChildren.isEmpty {
      wetChildren.first?.destroy()
    }

    updateGunPosition()
    mainCircle.physicsBody!.velocity = .zero
    mainCircle.physicsBody!.angularVelocity = .zero
    
    // Staggered because it seems to help things not go crazy. Should reassess
    // whether this stuff is necessary at some point.
    run(SKAction.wait(forDuration: 0.1)) { [weak self] in
      self?.mainCircle.position = scene.getRandomSpawnPoint()
      self?.updateGunPosition()
      self?.mainCircle.physicsBody!.velocity = .zero
      self?.mainCircle.physicsBody!.angularVelocity = .zero
      
      self?.run(SKAction.wait(forDuration: 0.1)) { [weak self] in
        self?.mainCircle.physicsBody!.velocity = .zero
        self?.mainCircle.physicsBody!.angularVelocity = .zero
        self?.initWetChildren()
        self?.updateGunPosition()
      }
    }
  }

  // MARK: Helpers

  func baptiseWetChild(
    newChild: DDDroplet,
    position: CGPoint? = .none,
    isInit: Bool = false
  ) {
    if wetChildren.contains(newChild) {
      return;
    }

    guard let scene = scene as? DDScene else {
      return
    }

    newChild.initPhysics()

    if newChild.parent == nil {
      newChild.onCatch(by: self)
      addChild(newChild)

      if let position = position {
        newChild.position = position
      }

      linkArms(with: newChild)
      let (damage, angle) = getDamage(from: newChild) ?? (0, 0)

      if damage > 0 {
        self.damageLast = damage
        // smaller angle as velocity increases
        let coneOfDamage = DDDamage(
          arcWithBerth: CGFloat.pi / max(log(damage), 1.5),
          andLength: 15.0)

        scene.rememberedDamage = coneOfDamage
        mainCircle.addChild(coneOfDamage)
        coneOfDamage.zRotation = angle
        coneOfDamage.position = newChild.position
      }
    } else {
      // TODO figure out if this branch is actually used
      let childPosition = newChild.getPosition(within: scene)
      let mainCirclePosition = mainCircle.getPosition(within: scene)
      let holyAngle = mainCirclePosition.angle(to: childPosition)

      newChild.removeFromParent()
      newChild.onCatch(by: self)
      addChild(newChild)

      // Fake initial position to set the joint in the right place
      newChild.position = CGPoint(
        x: mainCircle.position.x + cos(holyAngle) * getPlayerRadius(isInit: isInit),
        y: mainCircle.position.y + sin(holyAngle) * getPlayerRadius(isInit: isInit))

      linkArms(with: newChild)

      // Previous position, so it can be pulled in by the joint. We assume that
      // the actual DDPlayerNode is still at (0,0) [invariant]
      newChild.position = childPosition
    }

    wetChildren.insert(newChild)
    updateGunPosition()
    updateMainCircleSize()
  }

  func disown(wetChild: DDDroplet) {
    guard case .none = wetChild.lock else {
      return
    }

    wetChild.lock = .disowning
    guard wetChildren.remove(wetChild) != nil else {
      return
    }

    updateGunPosition()
    updateMainCircleSize()

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

  func linkArms(with newChild: DDDroplet) {
    // INVARIANT: do not change wetChild velocity in this method
    let joint = SKPhysicsJointSpring.joint(
      withBodyA: mainCircle.physicsBody!,
      bodyB: newChild.physicsBody!,
      anchorA: mainCircle.position,
      anchorB: newChild.position)

    joint.damping = 1.5
    joint.frequency = 4.0

    scene!.physicsWorld.add(joint)
    
    joints[mainCircle] = joints[mainCircle] ?? Set();
    joints[mainCircle]!.insert(joint)
    joints[newChild] = joints[newChild] ?? Set()
    joints[newChild]!.insert(joint)
  }

  func updateGunPosition() {
    gun.position = CGPoint(x: getPlayerRadius(), y: 0)
  }

  func updateMainCircleSize() {
    let ratio = getPlayerRadius() / getPlayerRadius(isInit: true)
    mainCircle.run(SKAction.scale(
      to: ratio,
      duration: Self.WAIT_RESIZE.duration
    ))
    gunAnchor.run(SKAction.scale(
      to: 1 / ratio,
      duration: Self.WAIT_RESIZE.duration
    ))
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

      if (distance > Self.DETACH_DISTANCE) {
        disown(wetChild: child)
        child.onRelease()
        child.removeFromParent()
        scene?.addChild(child)
      }
    }
    
    run(Self.WAIT_CHECK) { [weak self] in
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
      return run(Self.WAIT_FOLLOW) { [weak self] in
        self?.trackInputTouch()
      }
    }

    let mainCirclePosition = mainCircle.position
    let touchNodePosition = ddScene.moveTouchNode.position

    let diffX = touchNodePosition.x - mainCirclePosition.x
    let diffY = touchNodePosition.y - mainCirclePosition.y

    let sizeScaleFactor = log(CGFloat(wetChildren.count))
    
    let direction = CGVector(
      dx: (diffX * 800 * sizeScaleFactor),
      dy: (diffY * 400 * sizeScaleFactor)
    )
    
    applyMovementForce(direction) { [weak self] in
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
      return run(Self.WAIT_FOLLOW) { [weak self] in
        self?.trackInputController()
      }
    }
    
    let sizeScaleFactor = log(CGFloat(wetChildren.count))
    
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
    physicsBody.velocity.dx.magnitude > Self.MOVEMENT_SPEED_LIMIT.dx;

    let clampY =
    force.dy.sign == physicsBody.velocity.dy.sign &&
    physicsBody.velocity.dy.magnitude > Self.MOVEMENT_SPEED_LIMIT.dy;

    let forceClamped = CGVector(
      dx: force.dx.clamp(within: clampX ? 0 : .infinity),
      dy: force.dy.clamp(within: clampY ? 0 : .infinity))

    self.mainCircle.run(
      SKAction.applyForce(
        forceClamped,
        duration: Self.WAIT_FOLLOW.duration),
      completion: block)
  }

  // MARK: Jumping

  var jumpsSinceLastGroundTouch: Int8 = 0
  var holdingJump = false

  func getGroundContacts(withMask mask: DDBitmask = DDBitmask.GROUND_ANY) -> [SKPhysicsBody: Int] {
    return wetChildren
      .compactMap { wetChild in wetChild.physicsBody }
      .flatMap { wetBody in wetBody.allContactedBodies() }
      .filter { contactBody in (contactBody.categoryBitMask & mask.rawValue) != 0 }
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
    groundContacts.values.reduce(0) { sum, n in sum + n }
  }

  func handleCollision(on: DDDroplet, withDeath death: SKNode) {
    respawn()
  }

  func handleCollision(on droplet: DDDroplet, withDamage damage: DDDamage) {
    disown(wetChild: droplet)
  }

  func handleCollision(on: DDDroplet, withDroplet foreignDroplet: DDDroplet) {
    baptiseWetChild(newChild: foreignDroplet)
  }

  func handleCollision(on: DDDroplet, withGround ground: SKNode) {
    guard let pbGround = ground.physicsBody else {
      return
    }

    guard 0 != (DDBitmask.GROUND_ANY.rawValue & pbGround.categoryBitMask) else {
      fatalError("alleged ground contact with non-ground: \(ground)")
    }

    let isUppies = 0 != (DDBitmask.uppies.rawValue & pbGround.categoryBitMask)

    resetJumps()

    if isUppies {
      updateUppieability()
    }
  }

  func getDamage(from droplet: DDDroplet) -> (CGFloat, CGFloat)? {
    guard droplet.ownerLast != nil,
          droplet.ownerLast != self,
          let pb = droplet.physicsBody else {
      return .none
    }
    
    let magnitude = pb.velocity.magnitude
    return magnitude > 10 ? (magnitude, pb.velocity.angle) : .none
  }
  
  func handleForceTouch(force: CGFloat) {
    set(cravesJump: force > Self.TOUCH_FORCE_JUMP)
  }
  
  func resetJumps() {
    resetJumps(withContacts: self.getGroundContacts())
  }
  
  func resetJumps(withContacts groundContacts: [SKPhysicsBody: Int]) {
    guard jumpsSinceLastGroundTouch != 0 else {
      return
    }

    let contactCount = getGroundContactsTotalCount(withContacts: groundContacts)

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
    
    let groundContacts = getGroundContacts()
    let totalContactCount = getGroundContactsTotalCount(withContacts: groundContacts)
    
    self.resetJumps(withContacts: groundContacts)

    if totalContactCount >= 1 {
      let positionInScene = mainCircle.getPosition(within: scene!)

      for (body, contactCount) in groundContacts {
        let fractionOfTotal: CGFloat = CGFloat(contactCount) / CGFloat(totalContactCount)
        body.applyImpulse(
          CGVector(dx: 0, dy: -30 * Self.JUMP_SCALE * fractionOfTotal),
          at: positionInScene)
      }
    }

    guard jumpsSinceLastGroundTouch < 2 else {
      return
    }

    jumpsSinceLastGroundTouch += 1
    mainCircle.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 1.6 * Self.JUMP_SCALE))
    for wetChild in wetChildren {
      wetChild.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 0.5 * Self.JUMP_SCALE))
    }
  }

  func updateUppieability(canUppie shouldUppie: Bool) {
    guard let mcpb = mainCircle.physicsBody else {
      return
    }

    let canUppie = 0 == (mcpb.collisionBitMask & DDBitmask.uppies.rawValue)

    guard shouldUppie != canUppie else {
      return
    }

    if shouldUppie {
      let notUppiesBitmask = ~DDBitmask.uppies.rawValue
      mcpb.collisionBitMask &= notUppiesBitmask
      for child in wetChildren {
        child.physicsBody!.collisionBitMask &= notUppiesBitmask
      }
    } else {
      let groundContacts = getGroundContacts(withMask: DDBitmask.uppies)
      let isBelowOrInsideLeaf = groundContacts.keys
        .contains { groundPB in
          groundPB.node!.getPosition(within: scene!).y >
          mainCircle.getPosition(within: scene!).y + getPlayerRadius()
        }

      guard !isBelowOrInsideLeaf else {
        return
      }

      mcpb.collisionBitMask |= DDBitmask.uppies.rawValue
      for child in wetChildren {
        child.physicsBody!.collisionBitMask |= DDBitmask.uppies.rawValue
      }
    }
  }

  func updateUppieability() {
    guard let mcpb = mainCircle.physicsBody else {
      return
    }

    // Weight the main circle body as 5 children in the average
    let totalCount = CGFloat(wetChildren.count + 5)
    let avgVelocity = wetChildren
      .compactMap { child in child.physicsBody?.velocity.dy }
      .reduce(mcpb.velocity.dy / totalCount) { avg, v in avg + v / totalCount }
    
    guard avgVelocity < 0 || 50 < avgVelocity else {
      return
    }
    
    updateUppieability(canUppie: mcpb.velocity.dy > 0)
  }

  // MARK: Combat

  func chamberDroplet() {
    let closest: Optional<(DDDroplet, CGFloat)> = wetChildren
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
