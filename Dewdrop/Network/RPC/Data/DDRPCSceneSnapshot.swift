//
//  DDRPCSceneSnapshot.swift
//  DDRPCSceneSnapshot
//
//  Created by Logan Moore on 2021-08-24.
//

import Foundation

struct DDRPCSceneSnapshot : Codable {
  let nodes: [ DDNodeDelta ]
}
