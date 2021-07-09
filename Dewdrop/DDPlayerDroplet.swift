//
//  DDPlayerDroplet.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit

class DDPlayerDroplet : SKShapeNode {
  var shooter: Optional<PlayerNode> = .none
  var owner: Optional<PlayerNode> = .none
}
