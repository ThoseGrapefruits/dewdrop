//
//  DDScene.swift
//  Dewdrop
//
//  Created by Logan Moore on 02.07.2021.
//

import SpriteKit
import GameplayKit

class DDScene: SKScene {

  var graphs = [String : GKGraph]()
  var movementTouch: Optional<UITouch> = .none
  var movementTouchNode: SKNode = SKNode()

  override func sceneDidLoad() {
    addChild(movementTouchNode)
  }

  // MARK: Touch handling

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if movementTouch == .none {
      movementTouch = touches.first
      updateMovementTouchPosition()
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let mt = movementTouch, touches.contains(mt) {
      updateMovementTouchPosition()
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let mt = movementTouch, touches.contains(mt) {
      movementTouch = .none
    }
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with _: UIEvent?) {
    if let mt = movementTouch, touches.contains(mt) {
      movementTouch = .none
    }
  }

  // MARK: Helpers

  func updateMovementTouchPosition() {
    if let mt = movementTouch {
      let touchPosition = mt.location(in: self)
      movementTouchNode.position = CGPoint(
        x: touchPosition.x,
        y: touchPosition.y)
    } else if let camera = camera {
      movementTouchNode.position = CGPoint(
        x: camera.position.x, y: camera.position.y)
    }
  }
}
