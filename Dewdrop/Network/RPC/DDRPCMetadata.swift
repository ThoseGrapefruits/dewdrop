//
//  DDRPCMetadata.swift
//  DDRPCMetadata
//
//  Created by Logan Moore on 2021-08-21.
//

import Foundation

typealias RequestIndex = UInt8

struct DDRPCMetadata : Codable, CustomStringConvertible {
  let index: RequestIndex
  let indexWrapped: Bool

  var description: String {
    return "\(index)\( indexWrapped ? "w" : "" )"
  }
}
