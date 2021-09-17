//
//  GameViewController.swift
//  Dewdrop
//
//  Created by Logan Moore on 02.07.2021.
//

import UIKit
import SpriteKit
import GameKit
import GameplayKit

class DDViewController: UIViewController, DDSpawnDelegate {
  // MARK: Constants

  static let START_POSITION = CGPoint(x: 0, y: 160)

  // MARK: State

  let matchmaking = DDMatchmaking()
  var scene: Optional<DDScene> = .none

  // MARK: UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    matchmaking.findMatch(view: self) { [weak self] match, error in
      guard error == nil else {
        // TODO actual error handling
        fatalError(error.debugDescription)
      }

      guard let self = self else {
        return
      }

      print("--match--", GKLocalPlayer.local.gamePlayerID, match.players.map { p in p.gamePlayerID })

      DDNetworkMatch.singleton.match = match
      match.delegate = DDNetworkMatch.singleton

      self.scene = DDScene(fileNamed: "Scene")!
      self.scene!.addToScene(scene: self.scene!)
      DDNetworkMatch.singleton.scene = self.scene

      print("--starting client--")
      self.startLocalGame()

      DDNetworkMatch.singleton.updateHost { host in
        if DDNetworkMatch.singleton.isHost {
          print("--starting host--")
          try! DDNetworkMatch.singleton.startHost()
        }
      }
    }
  }

  // MARK: DDSpawnDelegate

  func handleSpawn(node: SKNode, from localGamePlayerID: String?) {
    if localGamePlayerID == GKLocalPlayer.local.gamePlayerID {
      guard let localPlayerNode = node as! DDPlayerNode? else {
        fatalError("Spawned node is not a DDPlayerNode: \( node )")
      }

      guard let scene = scene else {
        fatalError("No scene???")
      }

      let cameraNode = DDCameraNode()
      scene.addChild(cameraNode)
      cameraNode.position = DDViewController.START_POSITION
      scene.camera = cameraNode

      scene.playerNode = localPlayerNode
      localPlayerNode.start()
      cameraNode.track(localPlayerNode.mainCircle)

      let statsNode = DDNetworkStatsNode()
      statsNode.tracker = DDNetworkMatch.singleton.networkActivityTracker

      cameraNode.addChild(statsNode)

      scene.start()
    }

    // Other object sync, like the scene. Can ignore for now
  }

  // MARK: Helpers

  func startLocalGame() {
    DDNetworkMatch.singleton.waitForSceneSync { [weak self] scene in
      guard let self = self else {
        return
      }

      self.spawnLocalPlayerObjects()
    }
  }

  func spawnLocalPlayerObjects() {
    guard let view = self.view as! DDView? else {
      return
    }

    DDNetworkMatch.singleton.spawnDelegate = self

    try! DDNetworkMatch.singleton.requestSpawn(nodeType: .ddPlayerNode)

    // Present the scene
    view.presentScene(self.scene!)

    view.ignoresSiblingOrder = true
    view.showsFPS = true
    view.showsNodeCount = true
  }

  override var shouldAutorotate: Bool {
    return true
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    if UIDevice.current.userInterfaceIdiom == .phone {
      return .portrait.union(.portraitUpsideDown)
    } else {
      return .all
    }
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }
}
