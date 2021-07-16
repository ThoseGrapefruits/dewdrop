//
//  Position.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-11.
//

import Foundation
import SpriteKit

extension SKNode {
  func getPosition(within ancestor: SKNode) -> CGPoint {
    let (position, _) = getPositionAndRotation(within: ancestor)

    return position
  }

  func getPositionAndRotation(within ancestor: SKNode)
  -> (CGPoint, CGFloat) {
    guard let parent = parent, self != ancestor else {
      return (CGPoint.zero, CGFloat.zero)
    }

    let (parentPosition, parentRotation) = parent.getPositionAndRotation(
      within: ancestor)

    let position = CGPoint(
        x: parentPosition.x
           + cos(parentRotation) * position.x
           - sin(parentRotation) * position.y,
        y: parentPosition.y
           + sin(parentRotation) * position.x
           + cos(parentRotation) * position.y)

    let rotation = (zRotation + parentRotation).wrap(around: CGFloat.pi)

    return (position, rotation)
  }

  func getRotation(within ancestor: SKNode) -> CGFloat {
    let (_, rotation) = getPositionAndRotation(within: ancestor)

    return rotation;
  }
}
