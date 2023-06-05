//
//  DDNodeType.swift
//  DDNodeType
//
//  Created by Logan Moore on 2021-08-28.
//

import Foundation
import SpriteKit

let ddNodeTypeRegistry: [ DDNodeType: SKNode.Type ] = [
  .ddGun: DDGun.self,
  .ddPlayerDroplet: DDDroplet.self,
  .ddPlayerNode: DDPlayerNode.self,
  .ddScene: DDScene.self,
  .skNode: SKNode.self
]

enum DDNodeType : UInt8, Codable {
  case ddGun
  case ddPlayerDroplet
  case ddPlayerNode
  case ddScene
  case skNode

  func instantiate<NodeType : SKNode>() -> NodeType {
    let TypeReference = ddNodeTypeRegistry[self]

    return TypeReference?.init() as! NodeType
  }

  static func of(_ node: SKNode) -> DDNodeType {
    switch node {
      case is DDGun:
        return .ddGun
      case is DDDroplet:
        return .ddPlayerDroplet
      case is DDPlayerNode:
        return .ddPlayerNode
      case is DDScene:
        return .ddScene
      default:
        return .skNode
    }
  }
}
