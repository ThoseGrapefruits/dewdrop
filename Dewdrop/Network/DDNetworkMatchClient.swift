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
    guard !isHost else {
      try handleSpawnRequest(from: host!, data: DDRPCSpawnRequest(
        type: nodeType,
        localGamePlayerID: GKLocalPlayer.local.gamePlayerID
      ))
      return
    }

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
        handleSyncNodes(asClient: data)
        break
    }
  }

  // MARK: Message handlers

  func handleSceneSnapshot(asClient data: DDRPCSceneSnapshot) {
    for delta in data.nodes {
      apply(delta: delta)
    }
  }

  func handleSyncNodes(asClient data: DDRPCSyncNodes) {
    guard let scene = scene else {
      fatalError("Cannot sync nodes without scene")
    }

    let parent = data.nodes[0]

    if let parentDelegate = getDelegateFor(id: parent.id) {
      // Syncing a node within the scene

      let targetSyncNode = data.nodes[1]
      let targetNode = targetSyncNode.spawn
        ? {
          let node = targetSyncNode.type.instantiate()
          node.move(toParent: parentDelegate.node!)
          return node;
        }()
        : parentDelegate.node!.children.first { node in
          DDNodeType.of(node) == targetSyncNode.type
        }

      guard let targetNode = targetNode else {
        fatalError("No node of target type found within parent.")
      }

      let nodesInTarget = targetNode.bfs()

      if !targetSyncNode.spawn && nodesInTarget.count != data.nodes.count {
        fatalError(
          "\( nodesInTarget.count ) local nodes, received \( data.nodes.count )")
      }

      // The parent (first node) is already added.
      let zipped = zip(nodesInTarget.dropFirst(), data.nodes.dropFirst())

      for (localNode, remoteNode) in zipped {
        let _ = register(node: localNode, owner: host!, id: remoteNode.id)
      }

      if targetSyncNode.spawn {
        spawnDelegate?.handleSpawn(
          node: targetNode,
          from: data.sourceLocalGamePlayerID
        )
      }
    } else {
      if parent.type != .ddScene {
        fatalError("Found non-scene sync node with unknown parent")
      }

      let nodesInScene = scene.bfs()

      if nodesInScene.count != data.nodes.count {
        fatalError(
          "\( nodesInScene.count ) local nodes, received \( data.nodes.count )")
      }

      let zipped = zip(nodesInScene, data.nodes)

      for (localNode, remoteNode) in zipped {
        let _ = register(node: localNode, owner: host!, id: remoteNode.id)
      }

      onSceneSynced?(scene)
      onSceneSynced = nil
    }
  }

}
