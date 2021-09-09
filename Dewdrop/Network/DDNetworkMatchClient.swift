//
//  DDNetworkMatchClient.swift
//  DDNetworkMatchClient
//
//  Created by Logan Moore on 2021-09-08.
//

import Foundation
import SpriteKit
import GameKit

extension DDNetworkMatch {

  // MARK: API

  func requestSpawn(nodeType: DDNodeType) throws {
    let data = DDRPCSpawnRequest(
      type: nodeType,
      localGamePlayerID: GKLocalPlayer.local.gamePlayerID
    )
    let rpc = DDRPCData.spawnRequest(data)
    try sendHost(rpc, mode: .reliable)
  }

  // MARK: Message dispatch

  func receiveMessage(fromHost message: DDRPCData) {
    switch message {
      case .hostChange:
        // This is fine. Means we set the host normally and didn't have to rely
        // on the queued request. Should happen more often than not, but maybe
        // not when clients are connected over LAN.
        break
      case .lastSeen(let data):
        handleLastSeen(from: host!, data: data)
        break
      case .playerUpdate(_):
        fatalError("Received .playerUpdate as client")
        break
      case .spawnRequest(_):
        fatalError("Received .registrationRequest as client")
        break
      case .sceneSnapshot(let data):
        handleSceneSnapshot(asClient: data)
        break
      case .syncNodes(let data):
        handleSceneSync(asClient: data)
        break
    }
  }

  // MARK: Message handlers

  func handleSceneSnapshot(asClient data: DDRPCSceneSnapshot) {
    for delta in data.nodes {
      apply(delta: delta)
    }
  }

  func handleSceneSync(asClient data: DDRPCSyncNodes) {
    guard let scene = scene else {
      fatalError("Cannot sync scene without scene")
    }

    let nodesInScene = scene.bfs()

    if nodesInScene.count != data.nodes.count {
      fatalError(
        "\( nodesInScene.count ) local nodes, received \( data.nodes.count )")
    }

    for (localNode, remoteNode) in zip(nodesInScene, data.nodes) {
      let _ = register(node: localNode, owner: host!, id: remoteNode.id)
    }

    onSceneSynced?(scene)
    onSceneSynced = nil
  }

}
