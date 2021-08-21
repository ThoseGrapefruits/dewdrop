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

  func sendData(
    toAllPlayers data: DDNetworkData,
    with mode: GKMatch.SendDataMode
  ) throws {
    let data = DataHostChange()
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

    let data = DataHostChange()
    let message = DDNetworkData.hostChange(data: data)
    try sendData(toAllPlayers: message, with: .reliable)

    print("oldHost", oldHost)
  }

  func updateHost(player: GKPlayer?) {
    guard let player = player else {
      host = match?.players[0]
      match?.chooseBestHostingPlayer { [weak self] player in
        self?.updateHost(player: player)
      }
      return
    }

    host = player
  }
}
