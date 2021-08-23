//
//  DDNetworkMatch.swift
//  DDNetworkMatch
//
//  Created by Logan Moore on 2021-08-20.
//

import Foundation
import GameKit

typealias RegistrationID = Int16

class DDNetworkMatch : NSObject, GKMatchDelegate {

  let decoder = PropertyListDecoder()

  // MARK: State

  var host: GKPlayer? = .none
  var match: GKMatch? = .none
  var scene: SKScene? = .none

  var registry: [RegistrationID : DDNetworkDelegate] = [:]
  var registryIndex: RegistrationID = 0

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
    self.match = match
    // TODO
    if isHost {
      receiveMessage(asHost: data, fromRemotePlayer: player)
    } else if host == player {

    }
  }

  func match(
    _ match: GKMatch,
    didReceive data: Data,
    forRecipient recipient: GKPlayer,
    fromRemotePlayer player: GKPlayer
  ) {
    self.match = match
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
    self.match = match
    if player == host && (state == .disconnected || state == .unknown) {
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

  func register(node: SKNode, _ closure: (DDNetworkDelegate) -> Void) {
    
  }

  func registerLocal(node: SKNode) -> DDNetworkDelegate? {
    guard isHost else {
      return nil
    }

    let id = registryIndex
    registryIndex += 1

    let delegate = DDNetworkDelegate(id: id, node: node)
    registry[id] = delegate

    return delegate
  }

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

  // MARK: Internal API

  func receiveMessage(asHost data: Data, fromRemotePlayer player: GKPlayer) {
    var binary = PropertyListSerialization.PropertyListFormat.binary
    let decoded = try! decoder.decode(
      DDNetworkData.self,
      from: data,
      format: &binary)

    switch decoded {
      case .hostChange(_, _):
        break
      case .ping(_):
        break
      case .registrationRequest(_, _):
        break
    }
  }

  func receiveMessage(fromHost data: Data) {
    var binary = PropertyListSerialization.PropertyListFormat.binary
    let decoded = try! decoder.decode(
      DDNetworkData.self,
      from: data,
      format: &binary)

    switch decoded {
      case .hostChange(_, _):
        break
      case .ping(_):
        break
      case .registrationRequest(_, _):
        break
    }
  }
}
