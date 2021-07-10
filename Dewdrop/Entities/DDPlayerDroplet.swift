//
//  DDPlayerDroplet.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit

class DDPlayerDroplet : SKShapeNode {
  var shooter: Optional<DDPlayerNode> = .none
  var owner: Optional<DDPlayerNode> = .none
}
