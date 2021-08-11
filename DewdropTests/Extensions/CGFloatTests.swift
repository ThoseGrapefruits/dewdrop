//
//  CGFloatTests.swift
//  CGFloatTests
//
//  Created by Logan Moore on 2021-08-11.
//

import Foundation

import XCTest
@testable import Dewdrop
import SpriteKit

class CGFloatTests: XCTestCase {
  func testWrapSimple() throws {
    let difference = 0.7
    let result = (CGFloat.pi * 2 + difference).wrap(around: CGFloat.pi)
    XCTAssertEqual(result, difference, accuracy: 0.0000001)
  }

  func testWrapOverload() throws {
    let result = CGFloat(10000000).wrap(around: 1)
    XCTAssertEqual(result, 0, accuracy: 0.0000001)
  }
}
