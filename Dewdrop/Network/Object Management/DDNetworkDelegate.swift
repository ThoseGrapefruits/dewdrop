//
//  DDNetworkDelegate.swift
//  DDNetworkDelegate
//
//  Created by Logan Moore on 2021-08-15.
//

import Foundation
import SpriteKit

class DDNetworkDelegate {
  // MARK: State

  let id: NodeRegistrationID
  weak var node: SKNode?

  // MARK: Initialisation

  init(node: SKNode, id: NodeRegistrationID) {
    self.id = id
    self.node = node
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

    node.position =
      delta.position?.apply(to: node.position) ?? node.position
    node.zPosition =
      delta.zPosition?.apply(to: node.zPosition) ?? node.zPosition
    node.zRotation =
      delta.zRotation?.apply(to: node.zRotation) ?? node.zRotation
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
