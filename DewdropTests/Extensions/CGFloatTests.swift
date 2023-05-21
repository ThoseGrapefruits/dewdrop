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
  func testClampAboveRange() {
    let clamped = CGFloat(8).clamp(above: 0, below: 7)
    XCTAssertEqual(clamped, 7, accuracy: 0.001)
  }

  func testClampBelowRange() {
    let clamped = CGFloat(-7.022).clamp(above: -7, below: 0)
    XCTAssertEqual(clamped, -7, accuracy: 0.001)
  }

  func testClampInRange() {
    let clamped = CGFloat(0.99).clamp(above: 0, below: 1)
    XCTAssertEqual(clamped, 0.99, accuracy: 0.001)
  }

  func testClampWithinAboveRange() {
    let clamped = CGFloat(2).clamp(within: 1)
    XCTAssertEqual(clamped, 1, accuracy: 0.001)
  }

  func testClampWithinBelowRange() {
    let clamped = CGFloat(-2).clamp(within: 1)
    XCTAssertEqual(clamped, -1, accuracy: 0.001)
  }

  func testClampWithinInRange() {
    let clamped = CGFloat.zero.clamp(within: 1)
    XCTAssertEqual(clamped, CGFloat.zero, accuracy: 0.001)
  }

  func testWrapCirclePositiveOutside() throws {
    let result = (CGFloat.pi * 2 + 2).wrap(around: CGFloat.pi)
    XCTAssertEqual(result, 2, accuracy: 0.0000001)
  }

  func testWrapCirclePositiveBetween() throws {
    let result = (CGFloat.pi * 2 + 4).wrap(around: CGFloat.pi)
    XCTAssertEqual(result, -2.283, accuracy: 0.001)
  }
  
  func testWrapCirclePositiveOutsideFar() throws {
    let result = (CGFloat.pi * 4 + 2).wrap(around: CGFloat.pi)
    XCTAssertEqual(result, 2, accuracy: 0.0000001)
  }

  func testWrapCirclePositiveInside() throws {
    let result = (CGFloat.pi * 2 + 2).wrap(around: CGFloat.pi)
    XCTAssertEqual(result, 2, accuracy: 0.0000001)
  }
  
  func testWrapCircleNegativeBetween() throws {
    let result = (-CGFloat.pi * 2 - 4).wrap(around: CGFloat.pi)
    XCTAssertEqual(result, 2.283, accuracy: 0.001)
  }
  
  func testWrapCircleNegativeOutside() throws {
    let result = (-CGFloat.pi * 2 - 2).wrap(around: CGFloat.pi)
    XCTAssertEqual(result, -2, accuracy: 0.0000001)
  }

  func testWrapCircleNegativeInside() throws {
    let result = (-CGFloat.pi * 2 + 2).wrap(around: CGFloat.pi)
    XCTAssertEqual(result, 2, accuracy: 0.0000001)
  }
  
  func testWrapCircleNegativeOutsideFar() throws {
    let result = (-CGFloat.pi * 4 - 2).wrap(around: CGFloat.pi)
    XCTAssertEqual(result, -2, accuracy: 0.0000001)
  }

  func testWrapOverload() throws {
    let result = CGFloat(10e14).wrap(around: 1)
    XCTAssertEqual(result, 0, accuracy: 0.0000001)
  }
}
