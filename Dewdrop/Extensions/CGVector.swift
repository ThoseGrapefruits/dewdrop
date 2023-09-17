//
//  CGVector.swift
//  CGVector
//
//  Created by Logan Moore on 2021-08-30.
//

import Foundation
import SpriteKit

extension CGVector {
  var angle: CGFloat {
    get { atan2(dy, dx) }
  }
  
  /// Euclidean distance, treating this and the target vectors as (x, y) coordinates
  func distance(to: CGVector) -> CGFloat {
    return sqrt(pow(to.dx - dx, 2) + pow(to.dy - dy, 2))
  }
  
  var magnitude: CGFloat {
    get { distance(to: CGVector.zero) }
  }
}
