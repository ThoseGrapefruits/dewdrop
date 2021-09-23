//
//  DDRPCPlayerUpdate.swift
//  DDRPCPlayerUpdate
//
//  Created by Logan Moore on 2021-08-24.
//

import Foundation
import SceneKit

struct DDPlayerInput : Codable {
  let move: CGVector
  let aim: CGVector
}

struct DDRPCPlayerUpdate : Codable {
  let input: DDPlayerInput
}
