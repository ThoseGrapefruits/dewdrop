//
//  CGPointTests.swift
//  CGPointTests
//
//  Created by Logan Moore on 2021-08-13.
//

import Foundation

import Foundation

import XCTest
@testable import Dewdrop
import SpriteKit

class CGPointTests: XCTestCase {
  func testAngleToFromOrigin() {
    XCTAssertEqual(
      CGPoint.zero.angle(to: CGPoint(x: 1, y: 1)),
      CGFloat.pi / 4,
      accuracy: 0.0001)
  }

  func testAngleToIdentity() {
    XCTAssertEqual(CGPoint.zero.angle(to: CGPoint.zero), 0, accuracy: 0.0001)
  }

  func testAngleToNegative() {
    XCTAssertEqual(
      CGPoint(x: -1, y: -1).angle(to: CGPoint(x: -3, y: -2)),
      -2.6779,
      accuracy: 0.0001)
  }

  func testDistance() {
    XCTAssertEqual(
      CGPoint.zero.distance(to: CGPoint(x: 1, y: 1)),
      sqrt(2),
      accuracy: 0.0001)
  }

  func testDistanceNegative() {
    XCTAssertEqual(
      CGPoint.zero.distance(to: CGPoint(x: -1, y: -1)),
      sqrt(2),
      accuracy: 0.0001)
  }

  func testDistanceZero() {
    XCTAssertEqual(CGPoint.zero.distance(to: CGPoint.zero), 0, accuracy: 0.0001)
  }

  func testRotateQuadrants() {
    let q1 = CGPoint(x: 1, y: 2)

    let q2 = q1.rotate(by: CGFloat.pi / 2)
    let q3 = q2.rotate(by: CGFloat.pi / 2)
    let q4 = q3.rotate(by: CGFloat.pi / 2)

    XCTAssertEqual(q2.x, -2, accuracy: 0.0001)
    XCTAssertEqual(q2.y, 1, accuracy: 0.0001)

    XCTAssertEqual(q3.x, -1, accuracy: 0.0001)
    XCTAssertEqual(q3.y, -2, accuracy: 0.0001)

    XCTAssertEqual(q4.x, 2, accuracy: 0.0001)
    XCTAssertEqual(q4.y, -1, accuracy: 0.0001)
  }

  func testRotateZero() {
    let rotated = CGPoint.zero.rotate(by: CGFloat.pi * 3 / 4)

    XCTAssertEqual(rotated.x, 0, accuracy: 0.0001)
    XCTAssertEqual(rotated.y, 0, accuracy: 0.0001)
  }
}
