//
//  DDNetworkDelegate.swift
//  DDNetworkDelegate
//
//  Created by Logan Moore on 2021-08-15.
//

import Foundation
import GameKit
import SpriteKit

class DDNetworkDelegate {
  // MARK: State

  let id: DDNodeID
  weak var node: SKNode?
  let owner: GKPlayer

  // MARK: Initialisation

  init(node: SKNode, id: DDNodeID, owner: GKPlayer) {
    self.id = id
    self.node = node
    self.owner = owner
  }

  // MARK: Snapshots

  // TODO(optimisation): Hold 2 of these and swap between them to reduce malloc
  private var lastSnapshot: DDNodeSnapshot? = .none

  var capturedFields = DDNetworkDelegate.defaultCapturedFields

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

  func apply(delta: DDNodeDelta) {
    guard let node = node else {
      return
    }

    delta.apply(to: node)
  }

  func nextMessage() -> DDNodeDelta? {
    let lastSnapshot = lastSnapshot
    let snapshot = captureSnapshot()

    return snapshot?.delta(from: lastSnapshot, id: id)
  }

  func captureSnapshot() -> DDNodeSnapshot? {
    guard let node = node else {
      return .none
    }

    let snapshot = DDNodeSnapshot.capture(node, id: id)
    lastSnapshot = snapshot
    return snapshot
  }
}
