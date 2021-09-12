//
//  DDRPCSyncNodes.swift
//  DDRPCSyncNodes
//
//  Created by Logan Moore on 2021-08-30.
//

import Foundation
import SpriteKit

struct DDRPCSyncNodes : Codable {
  // Nodes in breadth-first search order, first being the parent node.
  let nodes: [ DDRPCSyncNode ]

  // The gamePlayerID of the sender, according to the sender. This is nil if
  // the message was sent from the server.
  let sourceLocalGamePlayerID: String?
}

struct DDRPCSyncNode: Codable {
  let id: DDNodeID
  let spawn: Bool
  let type: DDNodeType
}
