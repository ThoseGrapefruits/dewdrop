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
      print("--match--", GKLocalPlayer.local.gamePlayerID, match.players.map { p in p.gamePlayerID })

      guard error == nil else {
        // TODO actual error handling
        fatalError(error.debugDescription)
      }

      DDNetworkMatch.singleton.match = match
      match.delegate = DDNetworkMatch.singleton

      DDNetworkMatch.singleton.updateHost { [weak self] host in
        guard let self = self else {
          return
        }

        self.scene = DDScene(fileNamed: "Scene")!
        DDNetworkMatch.singleton.scene = self.scene

        if DDNetworkMatch.singleton.isHost {
          print("--starting as host--")

          self.startLocalGame() { [weak self] in
            self?.scene?.start()
          }

          try! DDNetworkMatch.singleton.startHost()
        } else {
          print("--starting as client--")
          self.startLocalGame()  { [weak self] in
            self?.scene?.start()
          }
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

      let cameraNode = DDCameraNode()
      scene!.addChild(cameraNode)
      cameraNode.position = DDViewController.START_POSITION
      scene!.camera = cameraNode

      localPlayerNode.start()
      cameraNode.track(localPlayerNode.mainCircle)

      let statsNode = DDNetworkStatsNode()
      statsNode.tracker = DDNetworkMatch.singleton.networkActivityTracker

      cameraNode.addChild(statsNode)
    }

    // Other object sync, like the scene. Can ignore for now
  }

  // MARK: Helpers

  func startLocalGame(_ closure: (() -> Void)? = .none) {
    DDNetworkMatch.singleton.waitForSceneSync { [weak self] scene in
      guard let self = self else {
        return
      }

      self.scene = scene
      self.spawnLocalPlayerObjects()
      closure?()
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
