//
//  BM.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SceneKit

class DDBitmask {
  static let all: UInt32 =  0b11111111111111111111111111111111
  static let none: UInt32 = 0b00000000000000000000000000000000

  static let GROUND: UInt32 =         0x1 << 0
  static let PLAYER_GUN: UInt32 =     0x1 << 1
  static let PLAYER_DROPLET: UInt32 = 0x1 << 2
}
