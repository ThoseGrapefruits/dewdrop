//
//  SKNodeCapturedFields.swift
//  SKNodeCapturedFields
//
//  Created by Logan Moore on 2021-08-26.
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
