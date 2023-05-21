//
//  CGFloatWrap.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-11.
//

import Foundation
import SpriteKit

extension CGFloat {

  /// Clamp this value within a given distance from `0`
  func clamp(within limit: CGFloat) -> CGFloat {
    return clamp(above: -abs(limit), below: abs(limit))
  }

  /// Clamp this value within the given range
  func clamp(above low: CGFloat, below high: CGFloat) -> CGFloat {
    if self > high {
      return high
    }

    if self < low {
      return low
    }

    return self
  }

  /// Seeks to truncate a value back into the `[-boundary,boundary]` range, modulo `boundary * 2`. This is mainly useful for pulling things back into the unit circle with `boundary: CGFloat.pi`.
  func wrap(around boundary: CGFloat) -> CGFloat {
    let doubleBoundary = boundary * 2
    let remainder = truncatingRemainder(dividingBy: doubleBoundary)
    
    let remainderAbs = abs(remainder)
    
    if (remainderAbs > boundary) {
      // We got back to a value in the range [-boundary*2, boundary*2], which
      //  needs to be pulled back into the   [-boundary,   boundary  ] range.
      return remainder < 0
        ?  doubleBoundary + remainder
        : -doubleBoundary + remainder
    }

    return remainder
  }
}
