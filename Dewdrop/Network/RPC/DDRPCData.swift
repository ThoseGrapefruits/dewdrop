//
//  DDRPCData.swift
//  DDRPCData
//
//  Created by Logan Moore on 2021-08-20.
//

import Foundation

enum DDRPCType : Int8, Codable, CustomStringConvertible {
  case hostChange
  case lastSeen
  case playerUpdate
  case sceneSnapshot
  case spawnRequest
  case syncNodes

  var description: String {
    switch self {
      case .hostChange:       return ".hostChange"
      case .lastSeen:      return ".lastSeen"
      case .playerUpdate:  return ".playerUpdate"
      case .sceneSnapshot: return ".sceneSnapshot"
      case .spawnRequest:  return ".spawnRequest"
      case .syncNodes:     return ".syncNodes"
    }
  }

  static func of(_ data: DDRPCData) -> DDRPCType {
    switch data {
      case .hostChange:       return .hostChange
      case .lastSeen(_):      return .lastSeen
      case .syncNodes(_):     return .syncNodes
      case .playerUpdate(_):  return .playerUpdate
      case .sceneSnapshot(_): return .sceneSnapshot
      case .spawnRequest(_):  return .spawnRequest
    }
  }
}

extension DDRPCData : CustomStringConvertible {
  var description: String {
    return DDRPCType.of(self).description
  }
}

enum DDRPCData : Codable {

  // MARK: Message types

  //   Name           Payload
  case hostChange                         // R
  case lastSeen      (DDRPCLastSeen)      // U
  case syncNodes     (DDRPCSyncNodes)     // R
  case playerUpdate  (DDRPCPlayerUpdate)  // U
  case sceneSnapshot (DDRPCSceneSnapshot) // U
  case spawnRequest  (DDRPCSpawnRequest)  // R

  // MARK: Codable

  enum CodingKeys: CodingKey {
    case type, data
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .hostChange:
        try container.encode(DDRPCType.hostChange, forKey: .type)
      case .lastSeen(let data):
        try container.encode(type: .lastSeen, data: data)
      case .playerUpdate(let data):
        try container.encode(type: .playerUpdate, data: data)
      case .sceneSnapshot(let data):
        try container.encode(type: .sceneSnapshot, data: data)
      case .syncNodes(let data):
        try container.encode(type: .syncNodes, data: data)
      case .spawnRequest(let data):
        try container.encode(type: .spawnRequest, data: data)
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let typeName = try container.decode(DDRPCType.self, forKey: .type)

    switch typeName {
      case .hostChange:
        self = .hostChange
      case .lastSeen:
        let data = try container.decode(DDRPCLastSeen.self, forKey: .data)
        self = .lastSeen(data)
      case .playerUpdate:
        let data = try container.decode(DDRPCPlayerUpdate.self, forKey: .data)
        self = .playerUpdate(data)
      case .sceneSnapshot:
        let data = try container.decode(DDRPCSceneSnapshot.self, forKey: .data)
        self = .sceneSnapshot(data)
      case .syncNodes:
        let data = try container.decode(DDRPCSyncNodes.self, forKey: .data)
        self = .syncNodes(data)
      case .spawnRequest:
        let data = try container.decode(DDRPCSpawnRequest.self, forKey: .data)
        self = .spawnRequest(data)
    }
  }
}

private extension KeyedEncodingContainer where K == DDRPCData.CodingKeys {
  mutating func encode<DataType>(
    type: DDRPCType,
    metadata: DDRPCMetadata,
    data: DataType
  ) throws where DataType : Encodable {
    try encode(type, forKey: .type)
    try encode(data, forKey: .data)
  }

  mutating func encode<DataType>(type: DDRPCType, data: DataType) throws
  where DataType : Encodable {
    try encode(type, forKey: .type)
    try encode(data, forKey: .data)
  }
}
