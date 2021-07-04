//
//  GameScene.swift
//  Dewdrop
//
//  Created by Logan Moore on 02.07.2021.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

  var entities = [GKEntity]()
  var graphs = [String : GKGraph]()

  private var lastUpdateTime : TimeInterval = 0
  private var label : SKLabelNode?
  private var spinnyNode : SKShapeNode?

  override func sceneDidLoad() {

    self.lastUpdateTime = 0

    // Get label node from scene and store it for use later
    self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
    if let label = self.label {
      label.alpha = 0.0
      label.run(SKAction.fadeIn(withDuration: 2.0))
    }

    // Create shape node to use during mouse interaction
    let w = (self.size.width + self.size.height) * 0.05
    self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)

    if let spinnyNode = self.spinnyNode {
      spinnyNode.lineWidth = 2.5

      spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
      spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                        SKAction.fadeOut(withDuration: 0.5),
                                        SKAction.removeFromParent()]))
    }
  }

  func getColor(hash: Int) -> SKColor {
    switch (hash % 7) {
    case 0: return SKColor.red;
    case 1: return SKColor.green;
    case 2: return SKColor.blue;
    case 3: return SKColor.yellow;
    case 4: return SKColor.orange;
    case 5: return SKColor.purple;
    case 6: return SKColor.magenta;
    default: return SKColor.white
    }

  }

  func touchDown(touch: UITouch) {
    if let n = self.spinnyNode?.copy() as! SKShapeNode? {
      n.position = touch.location(in: self)
      n.strokeColor = getColor(hash: touch.hash)
      self.addChild(n)
    }
  }

  func touchMoved(touch: UITouch) {
    if let n = self.spinnyNode?.copy() as! SKShapeNode? {
      n.position = touch.location(in: self)
      n.strokeColor = getColor(hash: touch.hash)
      self.addChild(n)
    }
  }

  func touchUp(touch: UITouch) {
    if let n = self.spinnyNode?.copy() as! SKShapeNode? {
      n.position = touch.location(in: self)
      n.strokeColor = getColor(hash: touch.hash)
      self.addChild(n)
    }
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let label = self.label {
      label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
    }

    for t in touches { self.touchDown(touch: t) }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchMoved(touch: t) }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchUp(touch: t) }
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchUp(touch: t) }
  }

  override func update(_ currentTime: TimeInterval) {
    // Called before each frame is rendered

    // Initialize _lastUpdateTime if it has not already been
    if (self.lastUpdateTime == 0) {
      self.lastUpdateTime = currentTime
    }

    // Calculate time since last update
    let dt = currentTime - self.lastUpdateTime

    // Update entities
    for entity in self.entities {
      entity.update(deltaTime: dt)
    }

    self.lastUpdateTime = currentTime
  }
}
