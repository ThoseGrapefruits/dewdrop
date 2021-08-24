//
//  DDNode.swift
//  DDNode
//
//  Created by Logan Moore on 2021-08-23.
//

import Foundation
import SpriteKit

enum CapturedFieldsNode {
  case position
  case physicsBody([CapturedFieldsPhysicsBody])
  case zPosition
  case zRotation
}

enum CapturedFieldsPhysicsBody {
  case angularDamping
  case angularVelocity
  case damping
  case mass
  case velocity
}

typealias DDNodeID = Int16

class DDNode : SKNode {
  // TODO(optimisation): Hold 2 of these and swap between them to reduce malloc
  private var lastSnapshot: DDNodeSnapshot? = .none

  var capturedFields: [CapturedFieldsNode] {
    get {
      return DDNode.defaultCapturedFields
    }
  }

  static let defaultCapturedFields: [ CapturedFieldsNode ] = [
    .position,
    .physicsBody([
      .angularDamping,
      .angularVelocity,
      .damping,
      .mass,
      .velocity
    ]),
    .zPosition,
    .zRotation
  ]

  var id: DDNodeID {
    get { fatalError("get id not implemented") }
  }

  func apply(delta: DDNodeDelta) {
    self.position =
      delta.position?.apply(to: self.position) ?? self.position
    self.zPosition =
      delta.zPosition?.apply(to: self.zPosition) ?? self.zPosition
    self.zRotation =
      delta.zRotation?.apply(to: self.zRotation) ?? self.zRotation
  }

  init(from snapshot: DDNodeSnapshot) {
    super.init()
    snapshot.restore(to: self)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func nextMessage() -> DDNodeChange {
    let lastSnapshot = lastSnapshot
    let snapshot = captureSnapshot()

    return snapshot.delta(from: lastSnapshot)
  }

  func captureSnapshot() -> DDNodeSnapshot {
    let snapshot = DDNodeSnapshot.capture(self)
    lastSnapshot = snapshot
    return snapshot
  }
}
