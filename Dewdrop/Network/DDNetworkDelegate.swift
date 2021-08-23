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

  let id: RegistrationID
  weak var node: SKNode?

  // MARK: Initialisation

  init(id: RegistrationID, node: SKNode) {
    self.id = id
    self.node = node
  }
}
