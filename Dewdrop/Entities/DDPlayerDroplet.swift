//
//  DDPlayerDroplet.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit

class DDPlayerDroplet : SKShapeNode {
  var lastOwner: Optional<DDPlayerNode> = .none
  var owner: Optional<DDPlayerNode> = .none

  func onCatch(by newOwner: DDPlayerNode) {
    owner = newOwner
  }

  func onRelease() {
    lastOwner = owner
    owner = nil
  }
}
