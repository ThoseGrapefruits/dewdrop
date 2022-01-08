//
//  DDSceneContactDelegates.swift
//  Dewdrop
//
//  Created by Logan Moore on 2022-01-08.
//

import Foundation
import SpriteKit

extension DDScene {
  func handleContactDidBeginDroplets(_ contact: SKPhysicsContact) {
    guard let dropletA = contact.bodyA.node as? DDPlayerDroplet,
          let dropletB = contact.bodyB.node as? DDPlayerDroplet
    else {
      return
    }

    guard (dropletA.owner == nil) != (dropletB.owner == nil),
          let newOwner = dropletA.owner ?? dropletB.owner
    else {
      return
    }

    let ownerless = dropletA.owner == nil ? dropletA : dropletB

    newOwner.baptiseWetChild(newChild: ownerless)
  }
}
