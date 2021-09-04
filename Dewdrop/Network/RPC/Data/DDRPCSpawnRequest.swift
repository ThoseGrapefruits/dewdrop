//
//  DDRPCSpawnRequest.swift
//  DDRPCSpawnRequest
//
//  Created by Logan Moore on 2021-08-22.
//

import Foundation
import SpriteKit

struct DDRPCSpawnRequest : Codable {
  let type: DDNodeType
  let snapshot: DDNodeSnapshot?
}
