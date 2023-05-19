//
//  BM.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-09.
//

import Foundation
import SceneKit

enum DDBitmask: UInt32 {
  typealias RawValue = UInt32
  
 
  case ALL  = 0b11111111111111111111111111111111
  case NONE = 0b00000000000000000000000000000000

  case ground        = 0b1
  case death         = 0b10
  case playerGun     = 0b100
  case playerDroplet = 0b1000
}
