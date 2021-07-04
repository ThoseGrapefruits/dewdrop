//
//  Player.swift
//  Dewdrop
//
//  Created by Logan Moore on 04.07.2021.
//

import Foundation
import SpriteKit

class PlayerNode: SKEffectNode, SceneAddable {

  // MARK: Constants

  let PD_RADIUS: CGFloat = 2.0
  let PD_CONNECTIONS_MAX = 5
  let PD_COUNT_INIT = 10
  let PD_COUNT_MAX = 20

  // MARK: State

  var wetChildren = Set<SKNode>()
  var joints: [SKNode: Set<SKPhysicsJointSpring>] = [:]

  // MARK: Initialisation

  override init() {
    super.init()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  // MARK: protocol SceneAddable

  func addToScene(scene: SKScene) {
    scene.addChild(self)
    initChildren()
  }

  // MARK: Helpers

  func addWetChild(newChild: SKShapeNode) {
    if wetChildren.contains(newChild) {
      return;
    }

    addChild(newChild)

    let closestWetChildren = wetChildren.reduce(
      into: Array<SKNode>(),
      { wc, child in
        let newDistance = distance(child.position, newChild.position)
        let insertionIndex = wc.firstIndex(where: { c in
          newDistance < distance(c.position, newChild.position)
        }) ?? wc.endIndex
        wc.insert(child, at: insertionIndex)

        if (wc.count > PD_CONNECTIONS_MAX) {
          wc.removeLast()
        }
      }
    )

    if (newChild.position.x.isNaN) {
      print("ass")
    }

    print(newChild.position, "closest", closestWetChildren.map({ c in c.position }))

    var jointsForWetChild = Set<SKPhysicsJointSpring>()
    joints[newChild] = jointsForWetChild

    for otherChild in closestWetChildren {
      let joint = SKPhysicsJointSpring.joint(
        withBodyA: newChild.physicsBody!,
        bodyB: otherChild.physicsBody!,
        anchorA: newChild.position,
        anchorB: otherChild.position
      )

      jointsForWetChild.insert(joint)
      joints[otherChild]?.insert(joint)
      scene?.physicsWorld.add(joint)
    }

    wetChildren.insert(newChild)
  }

  func removeWetChild(wetChild: SKShapeNode) {
    if wetChildren.remove(wetChild) != nil {
      if let jointsForWetChild = joints.removeValue(forKey: wetChild) {
        for joint in jointsForWetChild {
          let otherNode = joint.bodyA.node == self
            ? joint.bodyB.node!
            : joint.bodyA.node!

          joints[otherNode]?.remove(joint)

          scene!.physicsWorld.remove(joint)
        }
      }
    }
  }

  func initChildren() {
    for n in 1...PD_COUNT_INIT {
      let wetChild = SKShapeNode(circleOfRadius: PD_RADIUS)
      wetChild.name = "PD \(name ?? "unnamed") \(n-1)"

      let distance = log2(CGFloat(n))
      let rotation = distance * CGFloat.pi

      wetChild.position = CGPoint(
        x: cos(rotation) * distance * 2,
        y: sin(rotation) * distance * 2
      )

      wetChild.physicsBody = SKPhysicsBody(circleOfRadius: PD_RADIUS)

      addWetChild(newChild: wetChild)
    }
  }

  func distance(_ p: CGPoint, _ q: CGPoint) -> CGFloat {
    return sqrt(pow(q.x - p.x, 2) + pow(q.y - p.y, 2))
  }
}
