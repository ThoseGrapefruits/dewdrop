//
//  DDRPCMetadataReliable.swift
//  DDRPCMetadataReliable
//
//  Created by Logan Moore on 2021-08-28.
//

import Foundation

struct DDRPCMetadataReliable : Codable {
  let index: RequestIndex
  let indexWrapped: Bool
}
