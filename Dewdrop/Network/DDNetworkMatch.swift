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
  private static let updateInterval: CGFloat = 1/30

  // MARK: Properties

  private let decoder = PropertyListDecoder()

  // MARK: References

  var host: GKPlayer? = .none
  var match: GKMatch? = .none
  var scene: SKScene? = .none

  // MARK: External event handlers

  var onSceneLoaded: (() -> Void)? = .none
  var registrationResponseDelegate: ((DDNetworkDelegate) -> Void)? = .none

  // MARK: Network registries

  private var registry: [DDNodeID : DDNetworkDelegate] = [:]
  private var registryIndex: DDNodeID = 0
  private var requestIndicesSeenBy:
    [DDNetworkRPCType : [GKPlayer: (RequestIndex, Bool)] ] = [:]
  private var requestIndicesSeenFrom:
    [DDNetworkRPCType : [GKPlayer: (RequestIndex, Bool)] ] = [:]
  private var requestIndicesSent:
    [DDNetworkRPCType : (RequestIndex, Bool)] = [:]

  // MARK: Accessors

  var isHost: Bool {
    get { host != nil && host == GKLocalPlayer.local }
  }

  var localPlayerID: String {
    get { GKLocalPlayer.local.gamePlayerID }
  }

  // MARK: Game loops

  func startClient(_ closure: @escaping () -> Void) {
    updateHost { [weak self] _ in
      self?.onSceneLoaded = closure
    }
  }

  func startServer() throws {
    registerScene()
    try watchScene()
  }

  func watchScene() throws {
    guard isHost, let scene = scene else {
      return
    }

    let nodeSnapshots = registry.values.compactMap { delegate in
      delegate.nextMessage()
    }

    let (index, wrapped) = getNextRequestSendIndex(for: .sceneSnapshot)
    let metadata = DDRPCMetadataUnreliable(
      index: index,
      indexWrapped: wrapped,
      sender: GKLocalPlayer.local.gamePlayerID)
    let data = DDRPCSceneSnapshot(nodes: nodeSnapshots)
    let message = DDRPC.sceneSnapshot(metadata, data)
    try sendAll(message, mode: .unreliable)

    let waitForInterval = SKAction.wait(
      forDuration: DDNetworkMatch.updateInterval)
    scene.run(waitForInterval) { [weak self] in
      guard let self = self else {
        return
      }

      do {
        try self.watchScene()
      } catch {
        // TODO probably leave the match
        fatalError(error.localizedDescription)
      }
    }
  }

  // MARK: Registration

  func register(node: SKNode, owner: GKPlayer) -> DDNetworkDelegate? {
    guard isHost else {
      return nil
    }

    let id = registryIndex
    registryIndex += 1

    let delegate = DDNetworkDelegate(node: node, id: id, owner: owner)
    registry[id] = delegate

    return delegate
  }

  func registerScene() {
    guard let host = host, let scene = scene else {
      return
    }

    var nodesToRegister: [SKNode] = [scene]

    while let node = nodesToRegister.popLast() {
      let _ = register(node: node, owner: host)
      nodesToRegister.insert(contentsOf: node.children, at: 0)
    }

    // TODO send update
  }

  func requestRegistration(
    nodeType: DDNodeType,
    snapshot: DDNodeSnapshot
  ) throws {
    let (index, wrapped) = getNextRequestSendIndex(for: .registrationRequest)
    let metadata = DDRPCMetadataReliable(
      index: index, indexWrapped: wrapped, sender: localPlayerID)
    let data = DDRPCRegistrationRequest(type: nodeType, snapshot: snapshot)
    let message = DDRPC.registrationRequest(metadata, data)
    try sendHost(message, mode: .reliable)
  }

  // MARK: GKMatch

  func match(
    _ match: GKMatch,
    didReceive data: Data,
    fromRemotePlayer player: GKPlayer
  ) {
    if isHost {
      receiveMessage(asHost: data, fromRemotePlayer: player)
    } else if host == player {
      receiveMessage(fromHost: data)
    } else {
      fatalError("Received direct message from other non-host: \( data )")
    }
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
    if player == host && (state == .disconnected || state == .unknown) {
      // TODO pause game
      updateHost { newHost in
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

  func sendAll(_ data: DDRPC, mode: GKMatch.SendDataMode) throws {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let message = try encoder.encode(data)
    try match?.sendData(toAllPlayers: message, with: mode)
  }

  func sendHost(_ data: DDRPC, mode: GKMatch.SendDataMode) throws {
    guard let host = host else {
      return
    }

    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let message = try encoder.encode(data)
    try match?.send(message, to: [host], dataMode: mode)
  }

  // MARK: Host

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

  // MARK: Network message indices

  func getNextRequestSendIndex(for type: DDNetworkRPCType)
  -> (index: RequestIndex, wrapped: Bool) {
    let (existingValue, _) = requestIndicesSent[type] ?? (0, false)
    let newValue = existingValue + 1
    let wrapped = newValue < existingValue
    let result = (newValue, wrapped)

    requestIndicesSent[type] = result
    return result
  }

  func updateLastSeenRequest(
    from player: String,
    type: DDNetworkRPCType,
    metadata: DDRPCMetadataUnreliable
  ) -> (oldIndex: RequestIndex?, newIndex: RequestIndex, wrapped: Bool) {
    let senderID = metadata.sender

    var typeEntries = requestIndicesSeenFrom[type] ?? [:]
    requestIndicesSeenFrom[type] = typeEntries

    let sender = match?.players.first { player in
      player.gamePlayerID == senderID
    }

    guard let sender = sender else {
      fatalError("Unknown sender ID: \( senderID )")
    }

    let oldIndex = typeEntries[sender]?.0
    let newIndex = metadata.index
    let wrapped = metadata.indexWrapped

    typeEntries[sender] = (newIndex, wrapped)

    return (oldIndex, newIndex, wrapped)
  }

  // MARK: Messaging

  func receiveMessage(asHost data: Data, fromRemotePlayer player: GKPlayer) {
    var binary = PropertyListSerialization.PropertyListFormat.binary
    let decoded = try! decoder.decode(
      DDRPC.self,
      from: data,
      format: &binary)

    switch decoded {
      case .lastSeen(let metadata, let data):
        handleLastSeen(metadata: metadata, data: data)
        break
      case .ping(_):
        break
      case .playerUpdate(_, _):
        break
      case .registrationRequest(_, _):
        break
      case .sceneSnapshot(let metadata, _):
        fatalError("Received sceneSnapshot from non-host: \( metadata.sender )")
    }
  }

  func receiveMessage(fromHost data: Data) {
    var binary = PropertyListSerialization.PropertyListFormat.binary
    let decoded = try! decoder.decode(
      DDRPC.self,
      from: data,
      format: &binary)

    switch decoded {
      case .lastSeen(let metadata, let data):
        handleLastSeen(metadata: metadata, data: data)
        break
      case .ping(_):
        break
      case .playerUpdate(_, _):
        fatalError("Received .playerUpdate as client")
        break
      case .registrationRequest(_, _):
        fatalError("Received .registrationRequest as client")
        break
      case .sceneSnapshot(let metadata, let data):
        handleSceneSnapshotAsClient(metadata: metadata, data: data)
        break
    }
  }

  func shouldProcessMessage(
    type: DDNetworkRPCType,
    metadata: DDRPCMetadataUnreliable
  ) -> Bool {
    let (lastIndex, index, wrapped) = updateLastSeenRequest(
      from: metadata.sender, type: type, metadata: metadata)

    guard let lastIndex = lastIndex else {
      return true
    }

    return wrapped || lastIndex < index
  }


  // MARK: Message handlers

  func handleLastSeen(
    metadata: DDRPCMetadataUnreliable,
    data: DDRPCLastSeen
  ) {
    guard shouldProcessMessage(type: .lastSeen, metadata: metadata) else {
      return
    }

    let receiverID = metadata.sender

    var typeEntries = requestIndicesSeenFrom[data.type] ?? [:]
    requestIndicesSeenFrom[data.type] = typeEntries

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

  func handleSceneSnapshotAsClient(
    metadata: DDRPCMetadataUnreliable,
    data: DDRPCSceneSnapshot
  ) {
    guard shouldProcessMessage(type: .sceneSnapshot, metadata: metadata) else {
      return
    }

    for delta in data.nodes {
      registry[delta.id]?.apply(delta: delta)
    }
  }
}
