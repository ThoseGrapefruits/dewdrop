//
//  CGFloat.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-13.
//

import Foundation
import SpriteKit

extension CGPoint {
  
  /// Angle formed by a vector between this poind and the given point
  func angle(to: CGPoint) -> CGFloat {
    return atan2(to.y - y, to.x - x)
  }

  /// Euclidean distance between this point and another
  func distance(to: CGPoint) -> CGFloat {
    return sqrt(pow(to.x - x, 2) + pow(to.y - y, 2))
  }

  /// Rotate the point around (0, 0) by the given rotation, in radians
  func rotate(by rotation: CGFloat) -> CGPoint {
    return CGPoint(
      x: cos(rotation) * x - sin(rotation) * y,
      y: sin(rotation) * x + cos(rotation) * y)
  }
}
