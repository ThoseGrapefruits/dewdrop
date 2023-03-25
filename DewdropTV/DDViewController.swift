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

  var scene: Optional<DDScene> = .none
  var playerObjects: [DDPlayerNode] = []

  // MARK: UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    self.scene = DDScene(fileNamed: "TestLevel")!
    self.scene!.addToScene(scene: self.scene!)
    self.startLocalGame();
  }

  // MARK: Helpers

  func startLocalGame() {
    return self.spawnLocalPlayerObject()
  }

  func spawnLocalPlayerObject() {
    guard let view = self.view as! DDView? else {
      return
    }

    DDPlayerNode().addToScene(scene: self.scene!)

    // Present the scene
    view.presentScene(self.scene!)

    view.ignoresSiblingOrder = true
    view.showsFPS = true
    view.showsNodeCount = true
  }
}
