//
//  DDScene.swift
//  Dewdrop
//
//  Created by Logan Moore on 02.07.2021.
//

import SpriteKit
import GameplayKit
import Combine

class DDScene: SKScene, SKPhysicsContactDelegate {

  var graphs = [String : GKGraph]()
  var moveTouch: Optional<UITouch> = .none
  var moveTouchNode: DDMoveTouchNode = DDMoveTouchNode()
  let moveTouchPressureSubject = PassthroughSubject<CGFloat, Never>()

  var aimTouch: Optional<UITouch> = .none
  var aimTouchNode: DDAimTouchNode = DDAimTouchNode()

  var playerNode: Optional<DDPlayerNode> = .none

  override func sceneDidLoad() {
    vivifyBouncyLeaves()

    aimTouchNode.name = "Aim touch"
    addChild(aimTouchNode)

    moveTouchNode.name = "Movement touch"
    addChild(moveTouchNode)

    physicsWorld.contactDelegate = self
  }

  func vivifyBouncyLeaves() {
    let leafAnchors = children
      .filter { child in child.userData?["isLeafAnchor"] as? Bool ?? false }

    for leafAnchor in leafAnchors {
      let leaf = leafAnchor.children.first!

      leaf.physicsBody!.categoryBitMask = DDBitmask.ground
      leaf.physicsBody!.collisionBitMask = DDBitmask.all

      let leafScenePosition = leaf.getPosition(within: scene!)
      let springJoint = SKPhysicsJointSpring.joint(
        withBodyA: leaf.physicsBody!,
        bodyB: scene!.physicsBody!,
        anchorA: leafScenePosition,
        anchorB: CGPoint(
          x: leafScenePosition.x,
          y: leafScenePosition.y + 100))

      let strengthFactor = abs(leaf.position.x) * leaf.physicsBody!.mass;
      springJoint.damping = strengthFactor / 10000
      springJoint.frequency = strengthFactor / 1000

      let pinJoint = SKPhysicsJointPin.joint(
        withBodyA: leaf.physicsBody!,
        bodyB: scene!.physicsBody!,
        anchor: leafAnchor.position)

      scene!.physicsWorld.add(pinJoint)
      scene!.physicsWorld.add(springJoint)
    }
  }

  // MARK: Touch handling

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
      playerNode?.updateTouchForce(mt.force)
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

  // MARK: SKPhysicsContactDelegate

  func didBegin(_ contact: SKPhysicsContact) {
    guard let dropletA = contact.bodyA.node as? DDPlayerDroplet,
          let dropletB = contact.bodyB.node as? DDPlayerDroplet
    else {
      return
    }

    guard (dropletA.owner == nil) != (dropletB.owner == nil),
          let newOwner = dropletA.owner ?? dropletB.owner
    else {
      return
    }

    let ownerless = dropletA.owner == nil ? dropletA : dropletB

    newOwner.baptiseWetChild(newChild: ownerless)
  }

  // MARK: Helpers

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
    if let st = aimTouch {
      let touchPosition = st.location(in: self)
      aimTouchNode.position = CGPoint(
        x: touchPosition.x,
        y: touchPosition.y)
      aimTouchNode.fingerDown = true
    } else {
      aimTouchNode.fingerDown = false
      playerNode?.launchDroplet()
    }
  }
}
