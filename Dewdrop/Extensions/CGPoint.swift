//
//  CGFloat.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-13.
//

import Foundation
import SpriteKit

extension CGPoint {
  func angle(to: CGPoint) -> CGFloat {
    return atan2(
      to.y - self.y,
      to.x - self.x)
  }

  func distance(to: CGPoint) -> CGFloat {
    return sqrt(pow(to.x - x, 2) + pow(to.y - y, 2))
  }

  func rotate(by rotation: CGFloat) -> CGPoint {
    return CGPoint(
      x: cos(rotation) * x - sin(rotation) * y,
      y: sin(rotation) * x + cos(rotation) * y)
  }
}
