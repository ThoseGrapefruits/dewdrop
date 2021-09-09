//
//  DDNetworkMatchHost.swift
//  DDNetworkMatchHost
//
//  Created by Logan Moore on 2021-09-08.
//

import Foundation
import GameKit

extension DDNetworkMatch {

  // MARK: Message dispatch

  func receiveMessage(asHost message: DDRPCData, from sender: GKPlayer) {
    switch message {
      case .hostChange:
        fatalError("Received .hostChange as host")
      case .lastSeen(let data):
        handleLastSeen(from: sender, data: data)
        break
      case .playerUpdate(_):
        // TODO
        break
      case .spawnRequest(let data):
        try! handleSpawnRequest(from: sender, data: data)
        break
      case .sceneSnapshot(_):
        fatalError("Received .sceneSnapshot from non-host: \( sender )")
      case .syncNodes(_):
        fatalError("Received .nodeSync from non-host: \( sender )")
    }
  }

  // MARK: Message handlers

  func handleSpawnRequest(
    from sender: GKPlayer,
    data spawnRequest: DDRPCSpawnRequest
  ) throws {
    guard isHost else {
      fatalError("Cannot handle spawn request as non-host")
    }

    let instance = spawnRequest.type.instantiate()
    (instance as! DDSceneAddable?)?.addToScene(scene: scene!)

    let data = DDRPCSyncNodes(
      nodes: instance.bfs().map { node in DDRPCSyncNode(
        id: register(node: node, owner: sender).id,
        type: DDNodeType.of(node))
      },
      sourceLocalGamePlayerID: spawnRequest.localGamePlayerID
    )

    try sendAll(DDRPCData.syncNodes(data), mode: .reliable)
  }
}
