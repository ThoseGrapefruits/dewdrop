//
//  Position.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-11.
//

import Foundation
import SpriteKit

extension SKNode {

  func bfs() -> [SKNode] {
    var queue: [SKNode] = [self]
    var nodes: [SKNode] = []

    while !queue.isEmpty {
      let node = queue.removeFirst()
      nodes.append(node)
      queue.append(contentsOf: node.children)
    }

    return nodes
  }

  // MARK: getPositionAndRotation

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

    let cosZ = cos(zRotation)
    let sinZ = sin(zRotation)

    let position = CGPoint(
        x: position.x
           + cosZ * childPosition.x
           - sinZ * childPosition.y,
        y: position.y
           + sinZ * childPosition.x
           + cosZ * childPosition.y)

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

  // MARK: Network

  var isHost: Bool {
    get { DDNetworkMatch.singleton.isHost }
  }
}
