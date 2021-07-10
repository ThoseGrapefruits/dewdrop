//
//  GameViewController.swift
//  Dewdrop
//
//  Created by Logan Moore on 02.07.2021.
//

import UIKit
import SpriteKit
import GameplayKit

class DDViewController: UIViewController {

  var scene: Optional<DDScene> = .none

  override func viewDidLoad() {
    super.viewDidLoad()

    if let sceneNode = DDScene(fileNamed: "DDScene") {
      scene = sceneNode

      let playerNode = DDPlayerNode()

      playerNode.position = CGPoint(x: 0, y: 160)

      playerNode.addToScene(scene: sceneNode)

      // Present the scene
      if let view = self.view as! SKView? {
        view.presentScene(sceneNode)

        playerNode.start()

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
