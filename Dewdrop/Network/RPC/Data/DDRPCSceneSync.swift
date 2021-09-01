//
//  DDRPCSceneSync.swift
//  DDRPCSceneSync
//
//  Created by Logan Moore on 2021-08-30.
//

import Foundation

struct DDRPCSceneSync : Codable {
  // Nodes in breadth-first search order within the just-loaded-from-file scene
  let nodes: [ DDRPCSyncNode ]
}

struct DDRPCSyncNode: Codable {
  let id: DDNodeID
  let type: DDNodeType
}
