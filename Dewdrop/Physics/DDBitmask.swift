//
//  BM.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SceneKit

class DDBitmask {
  static let ALL:  UInt32 = 0b11111111111111111111111111111111
  static let NONE: UInt32 = 0b00000000000000000000000000000000

  static let ground:        UInt32 = 0x1 << 0
  static let playerGun:     UInt32 = 0x1 << 1
  static let playerDroplet: UInt32 = 0x1 << 2
}
