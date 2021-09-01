//
//  DDRPC.swift
//  DDRPC
//
//  Created by Logan Moore on 2021-08-20.
//

import Foundation

enum DDNetworkRPCType : Int8, Codable {
  case hostChange
  case lastSeen
  case playerUpdate
  case registrationRequest
  case sceneSnapshot
  case sceneSync
  case spawnNodes
}

extension DDRPC : CustomStringConvertible {
  var description: String {
    switch self {
      case .hostChange(_):             return ".hostChange"
      case .lastSeen(_, _):            return ".lastSeen"
      case .playerUpdate(_, _):        return ".playerUpdate"
      case .registrationRequest(_, _): return ".registrationRequest"
      case .sceneSnapshot(_, _):       return ".sceneSnapshot"
      case .sceneSync(_, _):           return ".sceneSync"
      case .spawnNodes(_, _):          return ".spawnNodes"
    }
  }
}

enum DDRPC : Codable {

  // MARK: Message types

  //   Name                 Metadata    Data
  case hostChange          (DDRPCMetadataReliable)
  case lastSeen            (DDRPCMetadataUnreliable, DDRPCLastSeen)
  case playerUpdate        (DDRPCMetadataUnreliable, DDRPCPlayerUpdate)
  case registrationRequest (DDRPCMetadataReliable,   DDRPCRegistrationRequest)
  case sceneSnapshot       (DDRPCMetadataUnreliable, DDRPCSceneSnapshot)
  case sceneSync           (DDRPCMetadataReliable,   DDRPCSceneSync)
  case spawnNodes          (DDRPCMetadataReliable,   DDRPCSpawnNodes)

  // MARK: Codable

  enum CodingKeys: CodingKey {
    case type, metadata, data
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .hostChange(let metadata):
        try container.encode(type: .hostChange, metadata: metadata)
      case .lastSeen(let metadata, let data):
        try container.encode(type: .lastSeen, metadata: metadata, data: data)
      case .registrationRequest(let metadata, let data):
        try container.encode(
          type: .registrationRequest, metadata: metadata, data: data)
      case .playerUpdate(let metadata, let data):
        try container.encode(
          type: .playerUpdate, metadata: metadata, data: data)
      case .sceneSnapshot(let metadata, let data):
        try container.encode(
          type: .sceneSnapshot, metadata: metadata, data: data)
      case .sceneSync(let metadata, let data):
        try container.encode(
          type: .sceneSync, metadata: metadata, data: data)
      case .spawnNodes(let metadata, let data):
        try container.encode(
          type: .spawnNodes, metadata: metadata, data: data)
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let typeName = try container.decode(
      DDNetworkRPCType.self,
      forKey: .type)

    switch typeName {
      case .hostChange:
        let metadata = try container.decodeMetadataReliable()
        self = .hostChange(metadata)
      case .lastSeen:
        let (metadata, data) = try container.decode(
          unreliable: DDRPCLastSeen.self)
        self = .lastSeen(metadata, data)
      case .playerUpdate:
        let (metadata, data) = try container.decode(
          unreliable: DDRPCPlayerUpdate.self)
        self = .playerUpdate(metadata, data)
      case .registrationRequest:
        let (metadata, data) = try container.decode(
          reliable: DDRPCRegistrationRequest.self)
        self = .registrationRequest(metadata, data)
      case .sceneSnapshot:
        let (metadata, data) = try container.decode(
          unreliable: DDRPCSceneSnapshot.self)
        self = .sceneSnapshot(metadata, data)
      case .sceneSync:
        let (metadata, data) = try container.decode(
          reliable: DDRPCSceneSync.self)
        self = .sceneSync(metadata, data)
      case .spawnNodes:
        let (metadata, data) = try container.decode(
          reliable: DDRPCSpawnNodes.self)
        self = .spawnNodes(metadata, data)
    }
  }
}

private extension KeyedDecodingContainer where Key == DDRPC.CodingKeys {
  func decode<DataType>(unreliable dataType: DataType.Type) throws
  -> (DDRPCMetadataUnreliable, DataType) where DataType : Decodable {
    let metadata = try decodeMetadataUnreliable()
    let data = try decode(dataType, forKey: .data)
    return (metadata, data)
  }

  func decode<DataType>(reliable dataType: DataType.Type) throws
  -> (DDRPCMetadataReliable, DataType) where DataType : Decodable {
    let metadata = try decodeMetadataReliable()
    let data = try decode(dataType, forKey: .data)
    return (metadata, data)
  }

  func decodeMetadataUnreliable() throws -> DDRPCMetadataUnreliable {
    return try decode(DDRPCMetadataUnreliable.self, forKey: .metadata)
  }

  func decodeMetadataReliable() throws -> DDRPCMetadataReliable {
    return try decode(DDRPCMetadataReliable.self, forKey: .metadata)
  }
}

private extension KeyedEncodingContainer where K == DDRPC.CodingKeys {
  mutating func encode(
    type: DDNetworkRPCType,
    metadata: DDRPCMetadataUnreliable
  ) throws {
    try encode(type, forKey: .type)
    try encode(metadata, forKey: .metadata)
  }

  mutating func encode(
    type: DDNetworkRPCType,
    metadata: DDRPCMetadataReliable
  ) throws {
    try encode(type, forKey: .type)
    try encode(metadata, forKey: .metadata)
  }

  mutating func encode<DataType>(
    type: DDNetworkRPCType,
    metadata: DDRPCMetadataUnreliable,
    data: DataType
  ) throws where DataType : Codable {
    try encode(type: type, metadata: metadata)
    try encode(data, forKey: .data)
  }

  mutating func encode<DataType>(
    type: DDNetworkRPCType,
    metadata: DDRPCMetadataReliable,
    data: DataType
  ) throws where DataType : Codable {
    try encode(type: type, metadata: metadata)
    try encode(data, forKey: .data)
  }
}
