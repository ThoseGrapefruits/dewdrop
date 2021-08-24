//
//  DDNode.swift
//  DDNode
//
//  Created by Logan Moore on 2021-08-23.
//

import Foundation
import SpriteKit

enum CapturedFieldsNode {
  case position
  case physicsBody([CapturedFieldsPhysicsBody])
  case zPosition
  case zRotation
}

enum CapturedFieldsPhysicsBody {
  case angularDamping
  case angularVelocity
  case damping
  case mass
  case velocity
}

protocol DDNode : SKNode {
  var networkDelegate: DDNetworkDelegate { get }

  init(from snapshot: DDNodeSnapshot)
}
