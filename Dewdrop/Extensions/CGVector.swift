//
//  CGVector.swift
//  CGVector
//
//  Created by Logan Moore on 2021-08-30.
//

import Foundation
import SpriteKit

extension CGVector {
  func distance(to: CGVector) -> CGFloat {
    return sqrt(pow(to.dx - dx, 2) + pow(to.dy - dy, 2))
  }
}
