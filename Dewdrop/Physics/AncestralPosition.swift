//
//  Position.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-11.
//

import Foundation
import SpriteKit


extension CGFloat {
    func format(f: String = "3.2") -> String {
      return String(format: "%\(f)f", self)
        .padding(toLength: 7, withPad: " ", startingAt: 0)
    }
}

extension SKNode {
  func getPosition(withinAncestor ancestor: SKNode) -> CGPoint {
    guard let parent = parent, self != ancestor else {
      return CGPoint(x: 0.0, y: 0.0)
    }

    let parentPosition = parent.getPosition(withinAncestor: ancestor)
    let parentRotation = parent.getRotation(withinAncestor: ancestor)

    return CGPoint(
        x: parentPosition.x
           + cos(parentRotation) * position.x
           - sin(parentRotation) * position.y,
        y: parentPosition.y
           + sin(parentRotation) * position.x
           + cos(parentRotation) * position.y)
  }

  func getRotation(withinAncestor ancestor: SKNode) -> CGFloat {
    guard let parent = parent, self != ancestor else {
      return CGFloat.zero
    }

    return zRotation + parent.getRotation(withinAncestor: ancestor)
  }
}
