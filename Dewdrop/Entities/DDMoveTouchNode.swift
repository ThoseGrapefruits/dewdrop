//
//  DDMovementTouchNode.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-07.
//

import Foundation
import SpriteKit

class DDMoveTouchNode : SKNode {
  let touchPosition = SKShapeNode(circleOfRadius: 20)

  private var _fingerDown = false

  var fingerDown: Bool {
    get {
      return _fingerDown
    }
    set {
      _fingerDown = newValue
      touchPosition.strokeColor = _fingerDown ? .cyan : .clear
    }
  }

  override init() {
    super.init()
    initVisual()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    initVisual()
  }

  func initVisual() {
    touchPosition.fillColor = .clear
    touchPosition.strokeColor = .clear

    addChild(touchPosition)
  }
}
