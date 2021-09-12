//
//  DDNetworkMatch.swift
//  DDNetworkMatch
//
//  Created by Logan Moore on 2021-08-20.
//

import Foundation
import GameKit
import SceneKit

typealias DDNodeID = Int16

struct SentRequest {
  var index: RequestIndex = 0
  var wrapped: Bool = false

  func increment() -> SentRequest {
    let wrapped = index == RequestIndex.max
    return SentRequest(
      index: wrapped ? 0 : index + 1,
      wrapped: wrapped)
  }
}

class DDNetworkMatch : NSObject, GKMatchDelegate {

  // MARK: Static properties

  static var singleton: DDNetworkMatch {
    get {
      if _singleton == nil {
        _singleton = DDNetworkMatch()
      }

      return _singleton!
    }
    set {
      _singleton = nil
    }
  }

  private static var _singleton: DDNetworkMatch? = .none
  private static let updateInterval: CGFloat = 1/10

  // MARK: Instances

  let networkActivityTracker = DDNetworkActivityTracker()
  private let decoder = PropertyListDecoder()
  private var decoderFormat =
    PropertyListSerialization.PropertyListFormat.binary

  // MARK: References

  var host: GKPlayer? = .none
  var match: GKMatch? = .none
  var scene: DDScene? = .none
  var spawnDelegate: DDSpawnDelegate? = .none

  // MARK: External event handlers

  var onSceneSynced: ((DDScene) -> Void)? = .none

  // MARK: Network registries

  private var registryByID: [DDNodeID : DDNetworkDelegate] = [:]
  private var registryByNode: [SKNode : DDNetworkDelegate] = [:]
  private var registryIndex: DDNodeID = 0

  private var requestLastSeenBy:
    [DDRPCType : [GKPlayer: (RequestIndex, Bool)] ] = [:]
  private var requestLastSeenFrom:
    [DDRPCType : [GKPlayer: (RequestIndex, Bool)] ] = [:]

  private var requestIndicesSent: [DDRPCType : SentRequest] = [:]

  private var playerNodesByPlayer: [ GKPlayer : DDPlayerNode ] = [:]

  // MARK: Accessors

  var isHost: Bool {
    get { host != nil && host == GKLocalPlayer.local }
  }

  // MARK: Game loops

  func waitForSceneSync(_ closure: @escaping (DDScene) -> Void) {
    guard onSceneSynced == nil else {
      fatalError("Double call to waitForScene")
    }

    self.onSceneSynced = closure
  }

  func startHost() throws {
    try registerScene()
    try watchScene()
  }

  func watchScene() throws {
    guard isHost, let scene = scene else {
      fatalError("Not host or no scene!")
    }

    let nodeSnapshots = registryByID.values.compactMap { delegate in
      delegate.nextMessage()
    }

    let data = DDRPCSceneSnapshot(nodes: nodeSnapshots)
    let message = DDRPCData.sceneSnapshot(data)
    try sendAll(message, mode: .unreliable)

    let waitForInterval = SKAction.wait(
      forDuration: DDNetworkMatch.updateInterval)
    scene.run(waitForInterval) { [weak self] in
      try! self?.watchScene()
    }
  }

  // MARK: Registration

  func apply(delta: DDNodeDelta) {
    getDelegateFor(id: delta.id)?.apply(delta: delta)
  }

  func getDelegateFor(id: DDNodeID) -> DDNetworkDelegate? {
    return registryByID[id]
  }

  func getDelegateFor(node: SKNode) -> DDNetworkDelegate? {
    return registryByNode[node]
  }

  func register(
    node: SKNode,
    owner: GKPlayer,
    id: DDNodeID? = .none
  ) -> DDNetworkDelegate {
    guard getDelegateFor(node: node) == nil else {
      fatalError(
        "Already registered node: \( node ), id: \( String(describing: id) )")
    }

    let id = id ?? {
      let id = registryIndex
      registryIndex += 1
      return id
    }()

    let delegate = DDNetworkDelegate(node: node, id: id, owner: owner)
    registryByID[id] = delegate
    registryByNode[node] = delegate

    return delegate
  }

  func registerScene() throws {
    guard let host = host, let scene = scene else {
      return
    }

    let nodesToSync = scene.bfs().map { node in
      return DDRPCSyncNode(
        id: register(node: node, owner: host).id,
        spawn: false,
        type: DDNodeType.of(node)
      )
    }

    let data = DDRPCSyncNodes(
      nodes: nodesToSync,
      sourceLocalGamePlayerID: .none)
    try sendAll(DDRPCData.syncNodes(data), mode: .reliable)

    onSceneSynced?(scene)
    onSceneSynced = nil
  }

  // MARK: Network message receiving

  func match(
    _ match: GKMatch,
    didReceive data: Data,
    fromRemotePlayer sender: GKPlayer
  ) {
    networkActivityTracker.recordReceive(data: data)

    let rpc = try! decoder.decode(
      DDRPC.self,
      from: data,
      format: &decoderFormat)

    guard shouldProcessMessage(
      from: sender,
      type: DDRPCType.of(rpc.data),
      metadata: rpc.metadata
    ) else {
      return
    }

    print("--recv--", sender.displayName, rpc)

    if isHost {
      receiveMessage(asHost: rpc.data, from: sender)
    } else if host == sender {
      receiveMessage(fromHost: rpc.data)
    } else {
      receiveMessage(asPeer: rpc.data, from: sender)
    }
  }

  func match(
    _ match: GKMatch,
    player: GKPlayer,
    didChange state: GKPlayerConnectionState
  ) {
    if player == host && (state == .disconnected || state == .unknown) {
      // TODO pause game
      updateHost { newHost in
        // TODO resync & unpause game
      }
    }
  }

  // MARK: Network sending — host

  func sendAll(_ data: DDRPCData, mode: GKMatch.SendDataMode) throws {
    guard let match = match else {
      return
    }

    let sendRequest = getNextRequestSendIndex(for: DDRPCType.of(data))
    let metadata = DDRPCMetadata(
      index: sendRequest.index, indexWrapped: sendRequest.wrapped)

    let rpc = DDRPC(metadata: metadata, data: data)

    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let message = try encoder.encode(rpc)

    print("--send--", match.players.map { p in p.displayName }, rpc)

    networkActivityTracker.recordSend(data: message, to: match.players)
    try match.sendData(toAllPlayers: message, with: mode)
  }

  // MARK: Network sending — client

  func sendHost(_ data: DDRPCData, mode: GKMatch.SendDataMode) throws {
    guard let host = host else {
      return
    }

    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary

    let sendRequest = getNextRequestSendIndex(for: DDRPCType.of(data))
    let metadata = DDRPCMetadata(
      index: sendRequest.index, indexWrapped: sendRequest.wrapped)

    let rpc = DDRPC(metadata: metadata, data: data)

    let message = try encoder.encode(rpc)
    let recipients = [host]

    networkActivityTracker.recordSend(data: message, to: recipients)
    try match?.send(message, to: recipients, dataMode: mode)
  }

  // MARK: Host

  func updateHost(
    player: GKPlayer? = nil,
    _ closure: @escaping (GKPlayer) -> Void
  ) {
    if let player = player {
      host = player
      if isHost {
        // This acts as a sort of lock. Because it and the scene snapshots are
        // sent via the .reliable channel, they have to arrive in order,
        // meaning that the host will definitely be set on all clients before
        // they receive any .syncNodes commands
        try? sendAll(.hostChange, mode: .reliable)
      }
      closure(player)
      return
    }

    print("--picking host--")

    match?.chooseBestHostingPlayer { [weak self] player in
      guard let self = self, let match = self.match else {
        return
      }

      if let player = player {
        print("--optimal host--", player.displayName)
        self.updateHost(player: player, closure)
      } else {
        let localPlayer = GKLocalPlayer.local as GKPlayer

        // TODO: sometimes one player gets the optimal and the other doesn't ???
        // this is dum. need to do host negotiation fallback
        let defaultHost = match.players.reduce(localPlayer) { lowest, player in
          switch lowest.displayName.compare(player.displayName)  {
            case .orderedAscending:
              return lowest
            default:
              return player
          }
        }

        print("--default host--", defaultHost.displayName)

        self.updateHost(player: defaultHost, closure)
      }
    }
  }

  // MARK: Network message indices

  func getNextRequestSendIndex(for type: DDRPCType) -> SentRequest {
    var sentRequest = requestIndicesSent[type]

    let new: SentRequest = sentRequest?.increment() ??
      SentRequest(index: 0, wrapped: false)

    requestIndicesSent[type] = new

    return new
  }

  func updateLastSeenRequest(
    from sender: GKPlayer,
    type: DDRPCType,
    _ metadata: DDRPCMetadata
  ) -> (oldIndex: RequestIndex?, newIndex: RequestIndex, wrapped: Bool) {
    var typeEntries = requestLastSeenFrom[type] ?? [:]
    requestLastSeenFrom[type] = typeEntries

    let oldIndex = typeEntries[sender]?.0
    let newIndex = metadata.index
    let wrapped = metadata.indexWrapped

    typeEntries[sender] = (newIndex, wrapped)

    return (oldIndex, newIndex, wrapped)
  }

  // MARK: Message dispatch

  func receiveMessage(asPeer message: DDRPCData, from sender: GKPlayer) {
    switch message {
      case .hostChange:
        handleHostChange(from: sender)
      default:
        fatalError("Received as peer: \( message )")
    }
  }

  func shouldProcessMessage(
    from sender: GKPlayer,
    type: DDRPCType,
    metadata: DDRPCMetadata
  ) -> Bool {
    let (lastIndex, index, wrapped) = updateLastSeenRequest(
      from: sender, type: type, metadata)

    guard let lastIndex = lastIndex else {
      return true
    }

    return wrapped || lastIndex < index
  }

  // MARK: Message handlers

  func handleHostChange(from sender: GKPlayer) {
    self.host = sender
  }

  func handleLastSeen(
    from sender: GKPlayer,
    data: DDRPCLastSeen
  ) {
    let receiverID = sender.gamePlayerID

    var typeEntries = requestLastSeenBy[data.type] ?? [:]
    requestLastSeenBy[data.type] = typeEntries

    let sender = match?.players.first { player in
      player.gamePlayerID == receiverID
    }

    guard let sender = sender else {
      fatalError("Unknown receiver ID: \( receiverID )")
    }

    let oldIndex = typeEntries[sender]?.0
    let newIndex = data.index
    let wrapped = oldIndex != nil && newIndex < oldIndex!

    typeEntries[sender] = (newIndex, wrapped)
  }
}
