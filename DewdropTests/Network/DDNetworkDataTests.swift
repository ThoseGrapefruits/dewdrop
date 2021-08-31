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
    let hostChange = DDRPC.registrationRequest(
      DDRPCMetadataReliable(index: 0, indexWrapped: false),
      DDRPCRegistrationRequest(
        type: DDNodeType.ddGun,
        snapshot: DDNodeSnapshot(
          id: DDNodeID.zero,
          physicsBody: nil,
          position: CGPoint.zero,
          zPosition: CGFloat.zero,
          zRotation: CGFloat.zero)))
    let encoder = encoder
    let decoder = decoder

    let hostChangeEncoded = try encoder.encode(hostChange)
    let hostChangeDecoded = try decoder.decode(
      DDRPC.self,
      from: hostChangeEncoded)

    if case (
      .registrationRequest(let metadata, let data),
      .registrationRequest(let metadataDecoded, let dataDecoded)
    ) = (hostChange, hostChangeDecoded) {
      XCTAssertEqual(metadata.index,        metadataDecoded.index)
      XCTAssertEqual(metadata.indexWrapped, metadataDecoded.indexWrapped)

      let snapshot = data.snapshot, snapshotDecoded = dataDecoded.snapshot
      XCTAssertNil(snapshotDecoded.physicsBody)
      XCTAssertEqual(snapshot.id,        snapshotDecoded.id)
      XCTAssertEqual(snapshot.position,  snapshotDecoded.position)
      XCTAssertEqual(snapshot.zPosition, snapshotDecoded.zPosition)
      XCTAssertEqual(snapshot.zRotation,  snapshotDecoded.zRotation)
    } else {
      XCTFail("registrationRequest or registrationRequestDecoded not right")
    }
  }
}
