//
//  DDDataRegistrationRequest.swift
//  DDDataRegistrationRequest
//
//  Created by Logan Moore on 2021-08-22.
//

import Foundation
import SpriteKit

enum NodeType : Int16, Codable {
  case ddGun
}

enum PropertyValue: Codable {
  case string(String)
}

let nodeTypeMap: [ NodeType : SKNode.Type ] = [
  .ddGun: DDGun.self
]

struct DDDataRegistrationRequest : Codable {
  let nodeType: NodeType
  let nodeProperties: [ String : PropertyValue ]

  func getNodeInstance() -> SKNode? {
    let node = nodeTypeMap[self.nodeType]

    return node?.init()
  }
}
