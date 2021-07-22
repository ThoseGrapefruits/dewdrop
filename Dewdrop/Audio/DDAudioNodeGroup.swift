//
//  SKAudioNodeGroup.swift
//  SKAudioNodeGroup
//
//  Created by Logan Moore on 2021-07-21.
//

import Foundation
import SpriteKit

class DDAudioNodeGroup : SKNode {
  var audioNodes = Set<SKAudioNode>()

  func add(fileNamed name: String) -> DDAudioNodeGroup {
    let audioNode = SKAudioNode(fileNamed: name)
    audioNode.autoplayLooped = false
    audioNodes.insert(audioNode)

    addChild(audioNode)
    return self
  }

  func playRandom() {
    audioNodes.randomElement()?.run(SKAction.play())
  }
}
