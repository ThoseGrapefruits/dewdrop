//
//  DDScene.swift
//  Dewdrop
//
//  Created by Logan Moore on 02.07.2021.
//

import SpriteKit
import GameplayKit
import Combine

class DDScene: SKScene, SKPhysicsContactDelegate, DDSceneAddable {
  var graphs = [String : GKGraph]()
  var moveTouch: UITouch? = .none
  var moveTouchNode: DDMoveTouchNode = DDMoveTouchNode()

  var aimTouch: UITouch? = .none
  var aimTouchNode: DDAimTouchNode = DDAimTouchNode()

  var playerNode: DDPlayerNode? = .none
  var spawnPointParent: SKNode? = .none
  var spawnPointIndex: Int = 0;

  let swipeUp = UISwipeGestureRecognizer()

  // MARK: Initialization

  func addToScene(scene: DDScene, position: CGPoint? = .none) {
    if (scene != self) {
      fatalError("no")
    }

    collectSpawnPoints()
    vivifyBouncyLeaves()
  }

  func start() {
    addChild(aimTouchNode)
    addChild(moveTouchNode)

    physicsWorld.contactDelegate = self

    swipeUp.delegate = self
    swipeUp.direction = UISwipeGestureRecognizer.Direction.up
    self.view!.addGestureRecognizer(swipeUp)
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

    if spawnPointIndex == spawnPointParent!.children.endIndex {
      spawnPointIndex = 0
    }

    return spawnPointParent!.children[spawnPointIndex].position
  }

  // MARK: Touch handling

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let mt = moveTouch else {
      moveTouch = touches.first
      updateMoveTouch()
      print("touches \(String(describing: event?.touches(for: swipeUp)))")
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
    handleContactDidBeginDroplets(contact)
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
}
