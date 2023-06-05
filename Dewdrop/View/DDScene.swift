//
//  DDScene.swift
//  Dewdrop
//
//  Created by Logan Moore on 02.07.2021.
//

import SpriteKit
import GameplayKit

class DDScene: SKScene, SKPhysicsContactDelegate, DDSceneAddable {
  var graphs = [String : GKGraph]()

  #if os(iOS)
  var moveTouch: UITouch? = .none
  var moveTouchNode: DDMoveTouchNode = DDMoveTouchNode()
  var aimTouch: UITouch? = .none
  var aimTouchNode: DDAimTouchNode = DDAimTouchNode()
  var playerNode: DDPlayerNode? = .none
  #else
  var playerNodes: [DDPlayerNode] = []
  #endif

  var spawnPointParent: SKNode? = .none
  var spawnPointIndex: Int = 0
  var sceneEffects: [DDSceneEffect] = []

  // MARK: Initialization

  func addToScene(scene: DDScene, position: CGPoint? = .none) -> Self {
    if (scene != self) {
      fatalError("adding scene to a different scene? no")
    }

    collectSpawnPoints()
    vivifyBouncyLeaves()
    
    setupSceneEffects()
    
    return self
  }

  func start() {
    initBoundaries()
    
    // TOUCH INPUT
    
#if os(iOS)
    aimTouchNode.name = "Aim touch"
    addChild(aimTouchNode)
    
    moveTouchNode.name = "Movement touch"
    addChild(moveTouchNode)
#endif
    
    // PHYSICS
    
    physicsWorld.contactDelegate = self
    physicsWorld.gravity.dy = -15
    
    // SCENE EFFECTS
    
    for effect in sceneEffects {
      effect.start()
    }
  }

  // MARK: Death & respawn

  func initBoundaries() {
    guard let scene = scene else {
      fatalError("No scene")
    }
    
    var index = 0
    let fillColors: [SKColor] = [.cyan, .magenta, .yellow, .black]
    for deathsRect in frame.getBorderRects(ofWidth: 100) {
      print("--dr-- \( deathsRect )")
      let deathsHead = SKShapeNode(rectOf: deathsRect.size)

      deathsHead.fillColor = fillColors[index]

      scene.addChild(deathsHead)
      deathsHead.position = deathsRect.origin
      let deathsBody = SKPhysicsBody(rectangleOf: deathsRect.size)
      
      deathsBody.affectedByGravity = false
      deathsBody.collisionBitMask = DDBitmask.NONE.rawValue
      deathsBody.categoryBitMask = DDBitmask.death.rawValue
      deathsBody.contactTestBitMask = DDBitmask.dropletPlayer.rawValue
      deathsBody.pinned = true
      
      deathsHead.physicsBody = deathsBody
                              
      index += 1
    }
  }

  // MARK: Spawn points

  func collectSpawnPoints() {
    spawnPointParent = children.first { child in
      child.userData?["isSpawnPointParent"] as? Bool ?? false
    }

    guard spawnPointParent != nil else {
      fatalError("Scene has no spawnPointParent")
    }
  }
  
  func getRandomSpawnPoint() -> CGPoint {
    guard let spawnPointParent = spawnPointParent, scene != nil else {
      fatalError("No scene or spawnPointParent")
    }
    
    return spawnPointParent.children.randomElement()!.position
  }

  func getNextSpawnPoint() -> CGPoint {
    guard let scene = scene, let spawnPointParent = spawnPointParent else {
      fatalError("No scene or spawnPointParent")
    }

    if spawnPointIndex == spawnPointParent.children.endIndex {
      spawnPointIndex = 0
    }
    
    spawnPointIndex += 1

    return spawnPointParent.children[spawnPointIndex].getPosition(within: scene)
  }

  // MARK: Leaf physics

  func vivifyBouncyLeaves() {
    let leafAnchors = children
      .filter { child in child.userData?["isLeafAnchor"] as? Bool ?? false }

    for leafAnchor in leafAnchors {
      let leaf = leafAnchor.children.first!
      let isUppies = leaf.userData?["isUppies"] as? Bool ?? false

      print("--setup-uppies-- \(isUppies)")

      leafAnchor.physicsBody = SKPhysicsBody()
      leafAnchor.physicsBody!.pinned = true

      leaf.physicsBody!.categoryBitMask = isUppies
        ? DDBitmask.groundUppies.rawValue
        : DDBitmask.ground.rawValue
      leaf.physicsBody!.collisionBitMask =
        DDBitmask.ALL.rawValue ^
        DDBitmask.GROUND_ANY.rawValue
      leaf.physicsBody!.contactTestBitMask =
        DDBitmask.dropletPlayer.rawValue

      print("--leafuppie-ctbm-- \( leaf.physicsBody!.contactTestBitMask.debugDescription )")

      let leafAnchorScenePosition = leafAnchor.getPosition(within: scene!)
      let leafScenePosition = leaf.getPosition(within: scene!)

      let anchorDistance = leafScenePosition.x - leafAnchorScenePosition.x
      let springOffsetX = 3 * anchorDistance
      let springOffsetY = 2 * abs(anchorDistance)

      let leafAttachPoint = CGPoint(
        x: leafScenePosition.x + anchorDistance,
        y: leafScenePosition.y)

      // TODO(logan): there are some assumptions being made around leaf neutral
      // positions being horizontal. This isn't a terrible idea, but I think in
      // reality it will look better to have the true angles varied a bit. Might
      // never vary enough to actually matter. It'd be worth testing with angled
      // leaves to see what breaks.
      let springJointPrimary = SKPhysicsJointSpring.joint(
        withBodyA: leaf.physicsBody!,
        bodyB: physicsBody!,
        anchorA: leafAttachPoint,
        anchorB: CGPoint(
          x: leafScenePosition.x + springOffsetX,
          y: leafScenePosition.y + springOffsetY))

      let springJointAntirotation = SKPhysicsJointSpring.joint(
        withBodyA: leaf.physicsBody!,
        bodyB: physicsBody!,
        anchorA: leafAttachPoint,
        anchorB: CGPoint(
          x: leafScenePosition.x - springOffsetX,
          y: leafScenePosition.y + springOffsetY))

      let damping = CGFloat(leafAnchor.userData!["damping"] as! Float)
      let frequency = CGFloat(leafAnchor.userData!["frequency"] as! Float)
      springJointPrimary.damping = damping
      springJointPrimary.frequency = frequency
      springJointAntirotation.damping = damping / 2
      springJointAntirotation.frequency = frequency / 2

      let pinJoint = SKPhysicsJointPin.joint(
        withBodyA: leaf.physicsBody!,
        bodyB: physicsBody!,
        anchor: leafAnchorScenePosition)

      physicsWorld.add(pinJoint)
      physicsWorld.add(springJointPrimary)
      physicsWorld.add(springJointAntirotation)
    }
  }
  
  // MARK: Scene effects

  func setupSceneEffects() {
    sceneEffects.append(DDWeatherCycle().addToScene(
      scene: scene as! DDScene,
      position: CGPoint(x: 0, y: 0)
    ))
  }

  #if os(iOS)
  // MARK: Touch input

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let mt = moveTouch else {
      moveTouch = touches.first
      updateMoveTouch()
      return
    }

    if aimTouch == nil {
      aimTouch = touches.first(where: { touch in touch != mt })
      updateAimTouch()
      playerNode?.chamberDroplet()
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let mt = moveTouch, touches.contains(mt) {
      updateMoveTouch()
      playerNode?.handleForceTouch(force: mt.force)
      moveTouchNode.touchPosition.strokeColor =
        mt.force > DDPlayerNode.TOUCH_FORCE_JUMP ? .red : .cyan
    }

    if let st = aimTouch, touches.contains(st) {
      updateAimTouch()
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let mt = moveTouch, touches.contains(mt) {
      moveTouch = .none
      updateMoveTouch()
    }

    if let st = aimTouch, touches.contains(st) {
      aimTouch = .none
      updateAimTouch()
    }
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with _: UIEvent?) {
    if let mt = moveTouch, touches.contains(mt) {
      moveTouch = .none
      updateMoveTouch()
    }

    if let st = aimTouch, touches.contains(st) {
      aimTouch = .none
      updateAimTouch()
    }
  }
  #endif

  // MARK: SKPhysicsContactDelegate

  func didBegin(_ contact: SKPhysicsContact) {
    guard !self.handleContactDropletDroplet(contact) else {
      return
    }
    
    guard !self.handleContactDropletWorld(contact) else {
      return
    }
  }
  
  func handleContactDropletDroplet(_ contact: SKPhysicsContact) -> Bool {
    guard let dropletA = contact.bodyA.node as? DDDroplet,
          let dropletB = contact.bodyB.node as? DDDroplet else {
      return false
    }

    guard (dropletA.owner == nil) != (dropletB.owner == nil),
          let newOwner = dropletA.owner ?? dropletB.owner
    else {
      return false
    }

    let ownerless = dropletA.owner == nil ? dropletA : dropletB

    newOwner.baptiseWetChild(newChild: ownerless)

    return true
  }
  
  func handleContactDropletWorld(_ contact: SKPhysicsContact) -> Bool {
    guard let nodeA = contact.bodyA.node,
          let nodeB = contact.bodyB.node else {
      return false
    }

    let droplet = nodeA as? DDDroplet ?? nodeB as? DDDroplet

    guard let droplet = droplet else {
      return false
    }

    for node in [ nodeA, nodeB ] {
      guard let bitmask = node.physicsBody?.categoryBitMask else {
        continue
      }
              
      if 0 != (bitmask & DDBitmask.death.rawValue) {
        droplet.owner?.handleCollision(on: droplet, withDeath: node)
        return true
      }
      
      if 0 != (bitmask & DDBitmask.GROUND_ANY.rawValue) {
        droplet.owner?.handleCollision(on: droplet, withGround: nodeA)
        return true;
      }
    }
    
    return false
  }

  // MARK: Helpers

  #if os(iOS)
  func updateMoveTouch() {
    if let mt = moveTouch {
      let touchPosition = mt.location(in: self)
      moveTouchNode.fingerDown = true
      moveTouchNode.position = CGPoint(
        x: touchPosition.x,
        y: touchPosition.y)
    } else {
      moveTouchNode.fingerDown = false
      if let playerNode = playerNode {
        moveTouchNode.position = CGPoint(
          x: playerNode.mainCircle.position.x,
          y: playerNode.mainCircle.position.y)
      }
    }
  }

  func updateAimTouch() {
    if let aimTouch = aimTouch {
      let touchPosition = aimTouch.location(in: self)
      aimTouchNode.position = CGPoint(
        x: touchPosition.x,
        y: touchPosition.y)
      aimTouchNode.fingerDown = true
    } else {
      aimTouchNode.fingerDown = false
      playerNode?.launchDroplet()
    }
  }
  #endif
}
