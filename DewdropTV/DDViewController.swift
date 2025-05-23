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

var playerIndices: [GCControllerPlayerIndex] = getPlayerIndices()

class DDViewController: GCEventViewController {
  // MARK: Constants

  static let START_POSITION = CGPoint(x: 0, y: 160)

  // MARK: State

  var scene: Optional<DDScene> = .none
  var playerObjects: [DDPlayerNode] = []

  // MARK: UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    self.scene = DDScene(fileNamed: "TestLevel")
    self.scene = self.scene!.addToScene(scene: self.scene!)
    self.listenForControllers();
    self.controllerUserInteractionEnabled = false;
    
    self.scene!.start()
  }

  // MARK: Helpers
  
  func listenForControllers() {
    NotificationCenter.default.addObserver(
      forName: .GCControllerDidConnect,
      object: nil,
      queue: .main
    ) { notification in
      guard playerIndices.count != 0 else {
        fatalError("2 many controllers")
      }

      let controllers = GCController.controllers()

      for controller in controllers {
        let alreadyAttached = self.scene!.children
          .compactMap { child in child as? DDPlayerNode }
          .contains { player in player.controller == controller }

        if (alreadyAttached) {
          continue
        }

        controller.playerIndex = playerIndices.removeFirst()
        self.spawnLocalPlayerObject(withController: controller)
      }
    }
  }

  func spawnLocalPlayerObject(withController controller: GCController) {
    guard let view = self.view as! DDView?, let scene = self.scene else {
      fatalError("no scene or view")
    }

    DDPlayerNode()
      .set(controller: controller)
      .addToScene(scene: scene, position: scene.getNextSpawnPoint())
      .start()

    // Present the scene
    view.presentScene(scene)

    view.ignoresSiblingOrder = true
    view.showsFPS = true
    view.showsNodeCount = true
  }
}

func getPlayerIndices() -> [GCControllerPlayerIndex] {
  return [ .index1, .index2, .index3, .index4, .indexUnset ];
}
