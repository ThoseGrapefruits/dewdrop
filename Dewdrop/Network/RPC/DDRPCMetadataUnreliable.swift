//
//  DDRPCMetadata.swift
//  DDRPCMetadata
//
//  Created by Logan Moore on 2021-08-21.
//

import Foundation

typealias RequestIndex = UInt16

struct DDRPCMetadataUnreliable : Codable {
  let index: RequestIndex
  let indexWrapped: Bool
  let sender: String
}
