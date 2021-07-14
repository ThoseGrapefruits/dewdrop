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
}
