//
//  DDNetworkRPC.swift
//  DDNetworkRPC
//
//  Created by Logan Moore on 2021-08-20.
//

import Foundation

enum DDNetworkRPCType : Int8, Codable {
  case hostChange
  case ping
  case registrationRequest
}

private extension KeyedDecodingContainer where Key == DDNetworkRPC.CodingKeys {
  func decode<DataType>(dataType: DataType.Type) throws
  -> (DDRPCMetadata, DataType) where DataType : Decodable {
    let metadata = try decodeMetadata()
    let data = try decode(dataType, forKey: .data)
    return (metadata, data)
  }

  func decodeMetadata() throws -> DDRPCMetadata {
    return try decode(DDRPCMetadata.self, forKey: .metadata)
  }
}

private extension KeyedEncodingContainer where K == DDNetworkRPC.CodingKeys {
  mutating func encode(
    type: DDNetworkRPCType,
    metadata: DDRPCMetadata
  ) throws {
    try encode(type, forKey: .type)
    try encode(metadata, forKey: .metadata)
  }

  mutating func encode<DataType>(
    type: DDNetworkRPCType,
    metadata: DDRPCMetadata,
    data: DataType
  ) throws where DataType : Codable {
    try encode(type: type, metadata: metadata)
    try encode(data, forKey: .data)
  }
}

enum DDNetworkRPC : Codable {

  // MARK: Message types

  //   Name                 Metadata    Data
  case hostChange          (DDRPCMetadata, DDRPCHostChange)
  case ping                (DDRPCMetadata)
  case registrationRequest (DDRPCMetadata, DDRPCRegistrationRequest)

  // MARK: Codable

  enum CodingKeys: CodingKey {
    case type, metadata, data
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .hostChange(let metadata, let data):
        try container.encode(
          type: .hostChange, metadata: metadata, data: data)
      case .ping(let metadata):
        try container.encode(
          type: .ping, metadata: metadata)
      case .registrationRequest(let metadata, let data):
        try container.encode(
          type: .registrationRequest, metadata: metadata, data: data)
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let typeName = try container.decode(
      DDNetworkRPCType.self,
      forKey: .type)

    switch typeName {
      case .hostChange:
        let (metadata, data) = try container.decode(
          dataType: DDRPCHostChange.self)
        self = .hostChange(metadata, data)
      case .ping:
        let metadata = try container.decodeMetadata()
        self = .ping(metadata)
      case .registrationRequest:
        let (metadata, data) = try container.decode(
          dataType: DDRPCRegistrationRequest.self)
        self = .registrationRequest(metadata, data)
    }
  }
}
