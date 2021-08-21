//
//  DDNetworkDataTests.swift
//  DDNetworkDataTests
//
//  Created by Logan Moore on 2021-08-21.
//

import Foundation

import XCTest
@testable import Dewdrop
import SpriteKit

class DDNetworkDataTests: XCTestCase {
  var decoder: PropertyListDecoder {
    get { return PropertyListDecoder() }
  }

  var encoder: PropertyListEncoder {
    get {
      let encoder = PropertyListEncoder()
      encoder.outputFormat = .binary
      return encoder
    }
  }

  func testHostChange() throws {
    let hostChange = DDNetworkData.hostChange(
      metadata: DDMetadata(sender: "walrus"),
      data: DDDataHostChange(oldHost: "old", newHost: "new"))
    let encoder = encoder
    let decoder = decoder

    let hostChangeEncoded = try encoder.encode(hostChange)
    let hostChangeDecoded = try decoder.decode(
      DDNetworkData.self,
      from: hostChangeEncoded)

    switch (hostChange, hostChangeDecoded) {
      case (
        .hostChange(let metadata, let data),
        .hostChange(let metadataDecoded, let dataDecoded)
      ):
        XCTAssertEqual(metadata.sender, metadataDecoded.sender)
        XCTAssertEqual(data.oldHost, dataDecoded.oldHost)
        XCTAssertEqual(data.newHost, dataDecoded.newHost)
      default:
        XCTFail("hostChange or hostChangeDecoded was not a hostChange")
    }
  }

  func testPing() throws {
    let ping = DDNetworkData.ping(metadata: DDMetadata(sender: "banana"))
    let encoder = encoder
    let decoder = decoder

    let pingEncoded = try encoder.encode(ping)
    let pingDecoded = try decoder.decode(
      DDNetworkData.self,
      from: pingEncoded)

    switch (ping, pingDecoded) {
      case (.ping(let metadata), .ping(let metadataDecoded)):
            XCTAssertEqual(metadata.sender, metadataDecoded.sender)
      default:
        XCTFail("ping or pingDecoded was not a ping")
    }
  }
}
