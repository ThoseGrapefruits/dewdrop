//
//  DDNetworking.swift
//  DDNetworking
//
//  Created by Logan Moore on 2021-08-20.
//

import Foundation
import GameKit

class DDNetworking : NSObject, GKMatchDelegate {

  // MARK: State

  var host: GKPlayer? = .none
  var match: GKMatch? = .none

  func send(
    _ data: Data,
    to: [GKPlayer],
    mode: GKMatch.SendDataMode
  ) throws {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let message = try encoder.encode(data)
    try match?.send(message, to: to, dataMode: mode)
  }

  func send(_ data: DDNetworkData, mode: GKMatch.SendDataMode) throws {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let message = try encoder.encode(data)
    try match?.sendData(toAllPlayers: message, with: mode)
  }

  func transitionHost(to newHost: GKPlayer) throws {
    guard let oldHost = host else {
      host = newHost
      return
    }

    let data = DataHostChange(
      oldHost: oldHost.gamePlayerID,
      newHost: newHost.gamePlayerID)
    let message = DDNetworkData.hostChange(data: data)
    try send(message, mode: .reliable)
  }

  func updateHost(
    player: GKPlayer? = nil,
    _ closure: @escaping (GKPlayer) -> Void
  ) {
    if let player = player {
      print("Determined host: \( player.gamePlayerID )")
      host = player
      closure(player)
      return
    }

    match?.chooseBestHostingPlayer { [weak self] player in
      guard let self = self, let match = self.match else {
        return
      }

      guard let player = player else {
        self.updateHost(player: match.players[0], closure)
        return
      }

      self.updateHost(player: player, closure)
    }
  }
}
