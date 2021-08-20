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

  private func getPositionAndRotation(
    within ancestor: SKNode,
    position childPosition: CGPoint,
    rotation childRotation: CGFloat
  ) -> (CGPoint, CGFloat) {
    guard let parent = parent, self != ancestor else {
      return (childPosition, childRotation)
    }

    let position = CGPoint(
        x: position.x
           + cos(zRotation) * childPosition.x
           - sin(zRotation) * childPosition.y,
        y: position.y
           + sin(zRotation) * childPosition.x
           + cos(zRotation) * childPosition.y)

    let rotation = (childRotation + zRotation).wrap(around: CGFloat.pi)

    return parent.getPositionAndRotation(
      within: ancestor, position: position, rotation: rotation)
  }

  func getPositionAndRotation(within ancestor: SKNode) -> (CGPoint, CGFloat) {
    return getPositionAndRotation(
      within: ancestor,
      position: CGPoint.zero,
      rotation: CGFloat.zero
    )
  }

  func getRotation(within ancestor: SKNode) -> CGFloat {
    let (_, rotation) = getPositionAndRotation(within: ancestor)

    return rotation;
  }
}
