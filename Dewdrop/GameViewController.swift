//
//  GameViewController.swift
//  Dewdrop
//
//  Created by Logan Moore on 02.07.2021.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    if let sceneNode = SKScene(fileNamed: "GameSceneSK") {
      let playerNode = PlayerNode()
      do {
        try playerNode.addToScene(scene: sceneNode)
      } catch {
        print(error)
      }

      playerNode.position = CGPoint(x: 0, y: 160)

      // Present the scene
      if let view = self.view as! SKView? {
        view.presentScene(sceneNode)

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
