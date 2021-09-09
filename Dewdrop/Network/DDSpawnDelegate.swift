//
//  SpawnDelegate.swift
//  SpawnDelegate
//
//  Created by Logan Moore on 2021-09-08.
//

import Foundation
import SpriteKit

protocol DDSpawnDelegate {
  func handleSpawn(node: SKNode, from localGamePlayerID: String?)
}
