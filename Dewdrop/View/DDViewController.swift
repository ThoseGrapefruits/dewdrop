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

class DDViewController: UIViewController {

  // MARK: Constants

  static let START_POSITION = CGPoint(x: 0, y: 160)

  // MARK: State

  let matchmaking = DDMatchmaking()
  var scene: Optional<DDScene> = .none

  override func viewDidLoad() {
    super.viewDidLoad()

    matchmaking.findMatch(view: self) { [weak self] match, error in
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
    guard let scene = scene, let view = self.view as! DDView? else {
      return
    }

    let playerNode = DDPlayerNode()
    // TODO positioning should be host-controlled
    playerNode.mainCircle.position = DDViewController.START_POSITION
    // TODO register the player node
    // playerNode.addToScene(scene: self.scene!)

    let cameraNode = DDCameraNode()
    scene.addChild(cameraNode)
    cameraNode.position = DDViewController.START_POSITION
    scene.camera = cameraNode

    // Present the scene
    view.presentScene(self.scene!)

    playerNode.start()
    cameraNode.track(playerNode.mainCircle)

    let statsNode = DDNetworkStatsNode()
    statsNode.tracker = DDNetworkMatch.singleton.networkActivityTracker

    cameraNode.addChild(statsNode)

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
