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
  
  // BASES //////////////////////////////////////////////
  
  case ALL           = 0b11111111111111111111111111111111
  case NONE          = 0b00000000000000000000000000000000

  // CATEGORIES — INDIVIDUAL ////////////////////////////

  case ground        =                                0b1
  case groundUppies  =                               0b10
  case death         =                              0b100
  case gunPlayer     =                             0b1000
  case dropletPlayer =                            0b10000
  case dropletFree   =                           0b100000

  // CATEGORIES — COMBINATIONS //////////////////////////
  
  case GROUND_ANY    =                               0b11
}
