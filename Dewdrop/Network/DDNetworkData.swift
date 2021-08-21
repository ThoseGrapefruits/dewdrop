//
//  DDNetworkData.swift
//  DDNetworkData
//
//  Created by Logan Moore on 2021-08-20.
//

import Foundation

enum DDNetworkData : Codable {
  case hostChange(data: DataHostChange)
  case ping

  // MARK: Codable

  enum CodingKeys: CodingKey {
    case data, typeName
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
      case .hostChange(let data):
        try container.encode("hostChange", forKey: .typeName)
        try container.encode(data, forKey: .data)

      case .ping:
        try container.encode("ping", forKey: .typeName)
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let typeName = try container.decode(String.self, forKey: .typeName)

    switch typeName {
      case "hostChange":
        let data = try container.decode(DataHostChange.self, forKey: .data)
        self = .hostChange(data: data)
      case "ping":
        self = .ping
      default:
        let context = DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unknown type name: \( typeName )")
        throw DecodingError.dataCorrupted(context)
    }
  }
}
