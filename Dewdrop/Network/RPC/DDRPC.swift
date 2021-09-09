//
//  DDRPC.swift
//  DDRPC
//
//  Created by Logan Moore on 2021-09-08.
//

import Foundation

struct DDRPC : Codable, CustomStringConvertible {
  let metadata: DDRPCMetadata
  let data: DDRPCData

  // MARK: CustomStringConvertible

  var description: String {
    return "DDRPC\( data.description ) \( metadata.description )"
  }
}
