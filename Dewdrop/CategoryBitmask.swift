//
//  BM.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SceneKit

class CategoryBitmask {
  static let all: UInt32 = 0b11111111111111111111111111111111

  static let GROUND: UInt32 = 0x1 << 1
  static let PLAYER_GUN: UInt32 = 0x1 << 2
  static let PLAYER_DROPLET: UInt32 = 0x1 << 3
}
