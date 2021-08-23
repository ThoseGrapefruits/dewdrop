//
//  DDNetworkData.swift
//  DDNetworkData
//
//  Created by Logan Moore on 2021-08-20.
//

import Foundation

enum DDNetworkDataType : Int8, Codable {
  case hostChange
  case ping
  case registrationRequest
}

private extension KeyedDecodingContainer where Key == DDNetworkData.CodingKeys {
  func decode<DataType>(dataType: DataType.Type) throws
  -> (DDMetadata, DataType) where DataType : Decodable {
    let metadata = try decodeMetadata()
    let data = try decode(dataType, forKey: .data)
    return (metadata, data)
  }

  func decodeMetadata() throws -> DDMetadata {
    return try decode(DDMetadata.self, forKey: .metadata)
  }
}

private extension KeyedEncodingContainer where K == DDNetworkData.CodingKeys {
  mutating func encode(
    type: DDNetworkDataType,
    metadata: DDMetadata
  ) throws {
    try encode(type, forKey: .type)
    try encode(metadata, forKey: .metadata)
  }

  mutating func encode<DataType>(
    type: DDNetworkDataType,
    metadata: DDMetadata,
    data: DataType
  ) throws where DataType : Codable {
    try encode(type: type, metadata: metadata)
    try encode(data, forKey: .data)
  }
}

enum DDNetworkData : Codable {

  // MARK: Message types

  //   Name                 Metadata    Data
  case hostChange          (DDMetadata, DDDataHostChange)
  case ping                (DDMetadata)
  case registrationRequest (DDMetadata, DDDataRegistrationRequest)

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
      DDNetworkDataType.self,
      forKey: .type)

    switch typeName {
      case .hostChange:
        let (metadata, data) = try container.decode(
          dataType: DDDataHostChange.self)
        self = .hostChange(metadata, data)
      case .ping:
        let metadata = try container.decodeMetadata()
        self = .ping(metadata)
      case .registrationRequest:
        let (metadata, data) = try container.decode(
          dataType: DDDataRegistrationRequest.self)
        self = .registrationRequest(metadata, data)
    }
  }
}
