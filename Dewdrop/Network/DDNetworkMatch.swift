//
//  DDNetworkMatch.swift
//  DDNetworkMatch
//
//  Created by Logan Moore on 2021-08-20.
//

import Foundation
import GameKit

class DDNetworkMatch : NSObject, GKMatchDelegate {

  // MARK: State

  var host: GKPlayer? = .none
  var match: GKMatch? = .none
  var registry: [Int16 : DDNetworkDelegate] = [:]

  // MARK: Accessors

  var isHost: Bool {
    get { host != nil && host == GKLocalPlayer.local }
  }

  // MARK: GKMatch

  func match(
    _ match: GKMatch,
    didReceive data: Data,
    fromRemotePlayer player: GKPlayer
  ) {
    // TODO
  }

  func match(
    _ match: GKMatch,
    didReceive data: Data,
    forRecipient recipient: GKPlayer,
    fromRemotePlayer player: GKPlayer
  ) {
    guard isHost else {
      return
    }

    try! send(data, to: [recipient], mode: .unreliable)
  }

  func match(
    _ match: GKMatch,
    player: GKPlayer,
    didChange state: GKPlayerConnectionState
  ) {
    if player == host {
      // TODO pause game
      updateHost { [weak self] newHost in
         // TODO resync & unpause game
      }
    }
  }

  func send(_ data: Data, to: [GKPlayer], mode: GKMatch.SendDataMode) throws {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let message = try encoder.encode(data)
    try match?.send(message, to: to, dataMode: mode)
  }

  func sendAll(_ data: DDNetworkData, mode: GKMatch.SendDataMode) throws {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let message = try encoder.encode(data)
    try match?.sendData(toAllPlayers: message, with: mode)
  }

  func sendHost(_ data: DDNetworkData, mode: GKMatch.SendDataMode) throws {
    guard let host = host else {
      return
    }

    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let message = try encoder.encode(data)
    try match?.send(message, to: [host], dataMode: mode)
  }

  // MARK: API

  func updateHost(
    player: GKPlayer? = nil,
    _ closure: @escaping (GKPlayer) -> Void
  ) {
    if let player = player {
      host = player
      closure(player)
      return
    }

    match?.chooseBestHostingPlayer { [weak self] player in
      guard let self = self, let match = self.match else {
        return
      }

      if let player = player {
        self.updateHost(player: player, closure)
      } else {
        self.updateHost(player: match.players[0], closure)
      }
    }
  }
}
