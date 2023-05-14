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
  var playerNode: DDPlayerNode? = .nil
  #else
  var playerNodes: [DDPlayerNode] = []
  #endif

  var spawnPointParent: SKNode? = .none
  var spawnPointIndex: Int = 0
  var sceneEffects: [DDSceneEffect] = []

  // MARK: Initialization

  func addToScene(scene: DDScene, position: CGPoint? = .none) -> Self {
    if (scene != self) {
      fatalError("no")
    }

    collectSpawnPoints()
    vivifyBouncyLeaves()
    
    setupSceneEffects()
    
    return self
  }

  func start() {
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

  // MARK: Spawn points

  func collectSpawnPoints() {
    spawnPointParent = children.first { child in
      child.userData?["isSpawnPointParent"] as? Bool ?? false
    }

    guard spawnPointParent != nil else {
      fatalError("Scene has no spawnPointParent")
    }
  }

  func getNextSpawnPoint() -> CGPoint {
    spawnPointIndex += 1
    
    guard let scene = scene, let spawnPointParent = spawnPointParent else {
      fatalError("No scene or spawnPointParent")
    }

    if spawnPointIndex == spawnPointParent.children.endIndex {
      spawnPointIndex = 0
    }

    return spawnPointParent.children[spawnPointIndex].getPosition(within: scene)
  }

  // MARK: Leaf physics

  func vivifyBouncyLeaves() {
    let leafAnchors = children
      .filter { child in child.userData?["isLeafAnchor"] as? Bool ?? false }

    for leafAnchor in leafAnchors {
      let leaf = leafAnchor.children.first!

      leafAnchor.physicsBody = SKPhysicsBody()
      leafAnchor.physicsBody?.pinned = true

      leaf.physicsBody!.categoryBitMask = DDBitmask.ground
      leaf.physicsBody!.collisionBitMask = DDBitmask.ALL ^ DDBitmask.ground

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
    sceneEffects.append(DDWeatherCycle()
      .addToScene(scene: scene as! DDScene, position: CGPoint(x: 0, y: 0)))
  }
  
  // MARK: Controller input
  

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
    guard let dropletA = contact.bodyA.node as? DDPlayerDroplet,
          let dropletB = contact.bodyB.node as? DDPlayerDroplet else {
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

    let droplet = nodeA as? DDPlayerDroplet ?? nodeB as? DDPlayerDroplet

    guard let droplet = droplet else {
      return false
    }

    if nodeA.physicsBody?.categoryBitMask == DDBitmask.ground {
      droplet.owner?.handleCollision(withGround: nodeA)
    } else if nodeB.physicsBody?.categoryBitMask == DDBitmask.ground {
      droplet.owner?.handleCollision(withGround: nodeB)
    } else {
      return false
    }
    
    return true
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
