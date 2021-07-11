//
//  Position.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-11.
//

import Foundation
import SpriteKit

extension SKNode {
  func getPosition(withinAncestor ancestor: SKNode) -> CGPoint {
    guard let parent = parent, self != ancestor else {
      return CGPoint(x: 0.0, y: 0.0)
    }

    let parentPosition = parent.getPosition(withinAncestor: ancestor)

    return CGPoint(
        x: parentPosition.x
           + cos(-parent.zRotation) * position.x
           - sin(-parent.zRotation) * position.y,
        y: parentPosition.y
           + sin(-parent.zRotation) * position.x
           + cos(-parent.zRotation) * position.y)
  }

  func getPositionWithinScene() -> CGPoint? {
    guard let scene = scene else {
      return .none
    }

    return getPosition(withinAncestor: scene)
  }
}
