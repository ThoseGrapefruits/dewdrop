//
//  DDScene.swift
//  Dewdrop
//
//  Created by Logan Moore on 02.07.2021.
//

import SpriteKit
import GameplayKit

class DDScene: SKScene {

  static let AIM_OFFSET: CGFloat = 20
  var graphs = [String : GKGraph]()
  var moveTouch: Optional<UITouch> = .none
  var moveTouchNode: DDMoveTouchNode = DDMoveTouchNode()

  var aimTouch: Optional<UITouch> = .none
  var aimTouchNode: DDAimTouchNode = DDAimTouchNode()

  var playerNode: Optional<PlayerNode> = .none

  override func sceneDidLoad() {
    moveTouchNode.name = "Movement touch"
    addChild(moveTouchNode)
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
      if let camera = camera {
        moveTouchNode.position = CGPoint(
          x: camera.position.x, y: camera.position.y)
      }
    }
  }

  func updateAimTouch() {
    if let st = aimTouch {
      let touchPosition = st.location(in: self)
      aimTouchNode.position = CGPoint(
        x: touchPosition.x,
        y: touchPosition.y + DDScene.AIM_OFFSET)
      aimTouchNode.fingerDown = true
    } else {
      aimTouchNode.fingerDown = false
      playerNode?.fireDroplet()
    }
  }
}
