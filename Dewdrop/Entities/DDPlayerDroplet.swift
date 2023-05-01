//
//  DDPlayerDroplet.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SpriteKit

class DDPlayerDroplet : SKShapeNode {
  weak var lastOwner: DDPlayerNode? = .none
  weak var owner: DDPlayerNode? = .none

  func onCatch(by newOwner: DDPlayerNode) {
    owner = newOwner
  }

  func onRelease() {
    lastOwner = owner
    owner = nil
  }
}
