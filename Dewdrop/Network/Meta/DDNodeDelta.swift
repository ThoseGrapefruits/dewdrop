//
//  DDNodeDelta.swift
//  DDNodeDelta
//
//  Created by Logan Moore on 2021-08-23.
//

import Foundation
import SpriteKit

struct PhysicsBodyDelta {
  var angularDamping: DDFieldChange<CGFloat>?
  var angularVelocity: DDFieldChange<CGFloat>?
  var damping: DDFieldChange<CGFloat>?
  var mass: DDFieldChange<CGFloat>?
  var velocity: DDFieldChange<CGVector>?
}

struct DDNodeDelta {
  var physicsBody: PhysicsBodyDelta?
  var position: DDFieldChange<CGPoint>?
  var zPosition: DDFieldChange<CGFloat>?
  var zRotation: DDFieldChange<CGFloat>?
}
