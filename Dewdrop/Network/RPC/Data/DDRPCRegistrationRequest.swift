//
//  DDRPCRegistrationRequest.swift
//  DDRPCRegistrationRequest
//
//  Created by Logan Moore on 2021-08-22.
//

import Foundation
import SpriteKit

struct DDRPCRegistrationRequest : Codable {
  let type: DDNodeType
  let snapshot: DDNodeSnapshot
}
