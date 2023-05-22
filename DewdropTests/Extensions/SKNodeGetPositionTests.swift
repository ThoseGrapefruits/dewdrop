//
//  SKNodeGetPositionTests.swift
//  SKNodeGetPositionTests
//
//  Created by Logan Moore on 2021-08-11.
//

import Foundation

import XCTest
@testable import Dewdrop
import SpriteKit

class SKNodeGetPositionTests: XCTestCase {
  func testGetPositionAndRotationParent() throws {
    let parent = SKNode()
    let child = SKNode()
    parent.addChild(child)

    child.position = CGPoint(x: -7, y: 3)
    child.zRotation = -CGFloat.pi

    let (position, rotation) = child.getPositionAndRotation(within: parent)

    XCTAssertEqual(position.x, -7,          accuracy: 0.000001)
    XCTAssertEqual(position.y, 3,          accuracy: 0.000001)
    XCTAssertEqual(rotation,   CGFloat.pi, accuracy: 0.0000001)
  }

  func testGetPositionAndRotationGrandparent() throws {
    let grandparent = SKNode()
    let parent = SKNode()
    let child = SKNode()
    grandparent.addChild(parent)
    parent.addChild(child)

    parent.position = CGPoint(x: 4, y: -2)
    parent.zRotation = CGFloat.pi / 6

    child.position = CGPoint(x: -7, y: 3)
    child.zRotation = -CGFloat.pi * 3 / 4

    let (position, rotation) =
      child.getPositionAndRotation(within: grandparent)

    XCTAssertEqual(position.x, -3.562, accuracy: 0.001)
    XCTAssertEqual(position.y, -2.902, accuracy: 0.001)
    XCTAssertEqual(rotation,   -1.8326,  accuracy: 0.0001)
  }

  func testGetPositionAndRotationSingleLevel() throws {
    let parent = SKNode()
    let child = SKNode()
    parent.addChild(child)

    child.position = CGPoint(x: 4, y: -2)
    child.zRotation = -CGFloat.pi / 7

    let (position, rotation) =
      child.getPositionAndRotation(within: parent)

    XCTAssertEqual(position.x, child.position.x, accuracy: 0.00001)
    XCTAssertEqual(position.y, child.position.y, accuracy: 0.00001)
    XCTAssertEqual(rotation,   child.zRotation,  accuracy: 0.00001)
  }

  func testGetPositionAndRotationTargetAncestorPositionAgnostic() throws {
    let parent = SKNode()
    let child = SKNode()
    parent.addChild(child)

    child.position = CGPoint(x: 4, y: -2)
    child.zRotation = -CGFloat.pi / 7

    let (initialPosition, initialRotation) =
      child.getPositionAndRotation(within: parent)

    parent.position = CGPoint(x: -7, y: 9)
    parent.zRotation = CGFloat.pi / 4

    let (afterPosition, afterRotation) =
      child.getPositionAndRotation(within: parent)

    XCTAssertEqual(initialPosition.x, afterPosition.x, accuracy: 0.000001)
    XCTAssertEqual(initialPosition.y, afterPosition.y, accuracy: 0.000001)
    XCTAssertEqual(initialRotation,   afterRotation,   accuracy: 0.000001)
  }

  func testGetPositionAndRotationPerformance() throws {
    let elderNode = SKNode()
    var node = elderNode
    let count = 5000
    for i in 0..<count {
      node.position = CGPoint(x: i, y: i)
      node.zRotation = (CGFloat.pi * 2 / CGFloat(count)) * CGFloat(i)
      let newNode = SKNode()
      node.addChild(newNode)
      node = newNode
    }

    measure {
      let (position, rotation) = node.getPositionAndRotation(within: elderNode)
      XCTAssertEqual(position.x, 3369.63,     accuracy: 0.01)
      XCTAssertEqual(position.y, -243408.14,   accuracy: 0.01)
      XCTAssertEqual(rotation,   -CGFloat.pi, accuracy: 0.00001)
    }
  }

  func testGetRotationWrap() throws {
      let parent = SKNode()
      let child = SKNode()
      parent.addChild(child)
      child.zRotation = -CGFloat.pi

      let rotation = child.getRotation(within: parent)

      XCTAssertEqual(rotation, CGFloat.pi, accuracy: 0.0000001)
  }
}
