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

  func testRegistrationRequest() throws {
    let hostChange = DDRPCData.spawnRequest(
      DDRPCSpawnRequest(
        type: DDNodeType.ddGun,
        localGamePlayerID: "TestID"))
    let encoder = encoder
    let decoder = decoder

    let hostChangeEncoded = try encoder.encode(hostChange)
    let hostChangeDecoded = try decoder.decode(
      DDRPCData.self,
      from: hostChangeEncoded)

    if case (
      .spawnRequest(let data),
      .spawnRequest(let dataDecoded)
    ) = (hostChange, hostChangeDecoded) {
      XCTAssertEqual(data.localGamePlayerID, dataDecoded.localGamePlayerID)
    } else {
      XCTFail("registrationRequest or registrationRequestDecoded not right")
    }
  }
}
