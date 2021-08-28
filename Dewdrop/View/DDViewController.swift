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
        print(error.debugDescription)
        return
      }

      guard
        let self = self,
        let sceneNode = DDScene(fileNamed: "DDScene"),
        let view = self.view as! SKView?
      else {
        return
      }

      DDNetworkMatch.singleton.match = match
      match.delegate = DDNetworkMatch.singleton

      DDNetworkMatch.singleton.updateHost { [weak self] _ in
        guard let self = self else {
          return
        }

        let playerNode = DDPlayerNode()
        playerNode.mainCircle.position = DDViewController.START_POSITION
        playerNode.addToScene(scene: sceneNode)

        let cameraNode = DDCameraNode()
        sceneNode.addChild(cameraNode)
        cameraNode.position = DDViewController.START_POSITION
        sceneNode.camera = cameraNode

        self.scene = sceneNode

        // Present the scene
        view.presentScene(sceneNode)

        playerNode.start()
        cameraNode.track(playerNode.mainCircle)

        view.ignoresSiblingOrder = true

        view.showsFPS = true
        view.showsNodeCount = true
      }
    }
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
