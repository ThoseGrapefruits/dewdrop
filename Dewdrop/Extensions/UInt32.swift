//
//  UInt32.swift
//  Dewdrop
//
//  Created by Logan Moore on 6/4/23.
//

import Foundation

extension UInt32 {
  var debugDescription: String {
    get {
      let string = String(self, radix: 2)
      return "".padding(toLength: 32 - string.count, withPad: "0", startingAt: 0) + string
    }
  }
}
