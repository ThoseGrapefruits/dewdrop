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
    let hostChange = DDNetworkRPC.hostChange(
      DDRPCMetadata(sender: "walrus"),
      DDRPCHostChange(oldHost: "old", newHost: "new"))
    let encoder = encoder
    let decoder = decoder

    let hostChangeEncoded = try encoder.encode(hostChange)
    let hostChangeDecoded = try decoder.decode(
      DDNetworkRPC.self,
      from: hostChangeEncoded)

    if case (
      .hostChange(let metadata, let data),
      .hostChange(let metadataDecoded, let dataDecoded)
    ) = (hostChange, hostChangeDecoded) {
      XCTAssertEqual(metadata.sender, metadataDecoded.sender)
      XCTAssertEqual(data.oldHost, dataDecoded.oldHost)
      XCTAssertEqual(data.newHost, dataDecoded.newHost)
    } else {
      XCTFail("hostChange or hostChangeDecoded was not a hostChange")
    }
  }

  func testPing() throws {
    let ping = DDNetworkRPC.ping(DDRPCMetadata(sender: "banana"))
    let encoder = encoder
    let decoder = decoder

    let pingEncoded = try encoder.encode(ping)
    let pingDecoded = try decoder.decode(
      DDNetworkRPC.self,
      from: pingEncoded)

    if case (
      .ping(let metadata),
      .ping(let metadataDecoded)
    ) = (ping, pingDecoded) {
      XCTAssertEqual(metadata.sender, metadataDecoded.sender)
    } else {
      XCTFail("ping or pingDecoded was not a ping")
    }
  }
}
