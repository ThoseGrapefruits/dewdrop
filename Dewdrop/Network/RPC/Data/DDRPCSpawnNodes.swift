//
//  DDRPCSpawnNodes.swift
//  DDRPCSpawnNodes
//
//  Created by Logan Moore on 2021-08-28.
//

import Foundation
import SpriteKit

struct DDRPCSpawnNodes : Codable {
  let nodes: [ DDRPCSpawnNode ]
}

struct DDRPCSpawnNode : Codable {
  let id: DDNodeID
  let parent: DDNodeID?
  let properties: DDNodeSnapshot
  let type: DDNodeType
}
