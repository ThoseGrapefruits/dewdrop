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

class DDViewController: UIViewController, GKGameCenterControllerDelegate {

  // MARK: GKGameCenterControllerDelegate

  func gameCenterViewControllerDidFinish(
    _ gameCenterViewController: GKGameCenterViewController
  ) {
    gameCenterViewController.dismiss(animated: true, completion: nil)
  }


  static let START_POSITION = CGPoint(x: 0, y: 160)

  var scene: Optional<DDScene> = .none

  func ensureGameCenter(_ closure: @escaping () -> Void) {
    GKLocalPlayer.local.authenticateHandler =
    { [weak self] viewController, error in
      guard let self = self else {
        return
      }

      if error != nil {
          // Player could not be authenticated.
          // Disable Game Center in the game.
          return
      }

      guard let viewController = viewController else {
        return closure()
      }

      self.present(viewController, animated: true, completion: nil)

      if GKLocalPlayer.local.isUnderage {
        // Hide explicit game content.
      }

      if GKLocalPlayer.local.isMultiplayerGamingRestricted {
        return
      }

      if GKLocalPlayer.local.isPersonalizedCommunicationRestricted {
        // Disable in game communication UI.
      }

      return closure()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    ensureGameCenter() { [weak self] in
      guard let self = self else {
        return
      }

      guard let sceneNode = DDScene(fileNamed: "DDScene") else {
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
      if let view = self.view as! SKView? {
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
      return .allButUpsideDown
    } else {
      return .all
    }
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }
}
