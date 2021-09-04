//
//  DDRPCTwoWay.swift
//  DDRPCTwoWay
//
//  Created by Logan Moore on 2021-09-03.
//

import Foundation

class DDRPCReply : Codable {
  internal init(re requestIndex: RequestIndex, type: DDRPCType, value: DDRPC) {
    self.originalRequestIndex = requestIndex
    self.originalRequestType = type
    self.value = value
  }

  let originalRequestIndex: RequestIndex
  let originalRequestType: DDRPCType
  let value: DDRPC
}
