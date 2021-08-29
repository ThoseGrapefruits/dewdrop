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
  private var requestLastSeenBy:
    [DDNetworkRPCType : [GKPlayer: (RequestIndex, Bool)] ] = [:]
  private var requestLastSeenFrom:
    [DDNetworkRPCType : [GKPlayer: (RequestIndex, Bool)] ] = [:]
  private var requestIndicesSent:
    [DDNetworkRPCType : (RequestIndex, Bool)] = [:]

  // MARK: Accessors

  var isHost: Bool {
    get { host != nil && host == GKLocalPlayer.local }
  }

  // MARK: Game loops

  func startClient(_ closure: @escaping () -> Void) {
    self.onSceneLoaded = closure
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
      indexWrapped: wrapped)
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
      index: index, indexWrapped: wrapped)
    let data = DDRPCRegistrationRequest(type: nodeType, snapshot: snapshot)
    let message = DDRPC.registrationRequest(metadata, data)
    try sendHost(message, mode: .reliable)
  }

  // MARK: Network message receiving

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


  // MARK: Network message sending

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
        print("--optimal host--", player.displayName)
        self.updateHost(player: player, closure)
      } else {
        let localPlayer = GKLocalPlayer.local as GKPlayer

        // TODO this probably isn't reliable. Not great to do anything
        // programmatic based on displayName but I think it's the only shared
        // identifier we have access to and makes things a lot easier than
        // negotiating a host more correctly.
        let defaultHost = match.players.reduce(localPlayer) { lowest, player in
          switch player.displayName.compare(lowest.displayName)  {
            case .orderedAscending:
              return player
            default:
              return lowest
          }
        }

        print("--default host--", defaultHost.displayName)

        self.updateHost(player: defaultHost, closure)
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
    from sender: GKPlayer,
    type: DDNetworkRPCType,
    _ metadata: DDRPCMetadataUnreliable
  ) -> (oldIndex: RequestIndex?, newIndex: RequestIndex, wrapped: Bool) {
    let senderID = sender.gamePlayerID
    var typeEntries = requestLastSeenFrom[type] ?? [:]
    requestLastSeenFrom[type] = typeEntries

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

  func receiveMessage(asHost data: Data, fromRemotePlayer sender: GKPlayer) {
    var binary = PropertyListSerialization.PropertyListFormat.binary
    let decoded = try! decoder.decode(
      DDRPC.self,
      from: data,
      format: &binary)

    switch decoded {
      case .lastSeen(let metadata, let data):
        handleLastSeen(from: sender, metadata: metadata, data: data)
        break
      case .playerUpdate(_, _):
        break
      case .registrationRequest(_, _):
        break
      case .sceneSnapshot(_, _):
        fatalError("Received sceneSnapshot from non-host: \( sender )")
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
        handleLastSeen(from: host!, metadata: metadata, data: data)
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
    from sender: GKPlayer,
    type: DDNetworkRPCType,
    _ metadata: DDRPCMetadataUnreliable
  ) -> Bool {
    let (lastIndex, index, wrapped) = updateLastSeenRequest(
      from: sender, type: type, metadata)

    guard let lastIndex = lastIndex else {
      return true
    }

    return wrapped || lastIndex < index
  }


  // MARK: Message handlers

  func handleLastSeen(
    from sender: GKPlayer,
    metadata: DDRPCMetadataUnreliable,
    data: DDRPCLastSeen
  ) {
    guard shouldProcessMessage(from: sender, type: .lastSeen, metadata) else {
      return
    }

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

  func handleSceneSnapshotAsClient(
    metadata: DDRPCMetadataUnreliable,
    data: DDRPCSceneSnapshot
  ) {
    guard shouldProcessMessage(
      from: host!, type: .sceneSnapshot, metadata
    ) else {
      return
    }

    for delta in data.nodes {
      registry[delta.id]?.apply(delta: delta)
    }
  }
}
