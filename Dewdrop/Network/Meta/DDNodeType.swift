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
  .ddPlayerDroplet: DDPlayerDroplet.self,
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
}

func instantiate<NodeType : SKNode>(type: DDNodeType) -> NodeType {
  let TypeReference = ddNodeTypeRegistry[type]

  return TypeReference?.init() as! NodeType
}
