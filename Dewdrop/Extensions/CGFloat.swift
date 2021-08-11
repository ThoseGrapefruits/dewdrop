//
//  CGFloatWrap.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-11.
//

import Foundation
import SpriteKit

extension CGFloat {
  func clamp(within limit: CGFloat) -> CGFloat {
    return clamp(above: -abs(limit), below: abs(limit))
  }

  func clamp(above low: CGFloat, below high: CGFloat) -> CGFloat {
    if self > high {
      return high
    }

    if self < low {
      return low
    }

    return self
  }

  func wrap(around boundary: CGFloat) -> CGFloat {
    var current = self
    while (current > boundary) {
      current -= boundary * 2
    }

    while (current < -boundary) {
      current += boundary * 2
    }

    return current
  }
}
