//
//  DDAimTouchNode.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-08.
//

import Foundation
import SpriteKit

class DDAimTouchNode : SKNode {
  let touchPosition = SKShapeNode(circleOfRadius: 20)

  private var _fingerDown = false

  var fingerDown: Bool {
    get {
      return _fingerDown
    }
    set {
      _fingerDown = newValue
      touchPosition.strokeColor = newValue ? .cyan : .clear
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
  
  // MARK: SKNode
  
  override var name: String? {
    get { "DDAimTouchNode \(touchPosition.position.debugDescription)" }
    set {}
  }
}
