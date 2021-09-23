//
//  DDNetworkStatsNode.swift
//  DDNetworkStatsNode
//
//  Created by Logan Moore on 2021-08-29.
//

import Foundation
import SceneKit
import SpriteKit

class DDNetworkStatsNode : SKNode {
  var tracker: DDNetworkActivityTracker? = .none

  let intervalSeconds: TimeInterval = 1
  let lines = [
    SKLabelNode(text: "Requests: "),
    SKLabelNode(text: "Largest: "),
    SKLabelNode(text: "Mean bytes: "),
    SKLabelNode(text: "Median bytes: ")
  ]
  let padding: CGFloat = 4

  // MARK: Initialisation

  func start() {
    position = CGPoint(
      x: (-scene!.frame.width / 2) + padding,
      y: (scene!.frame.height / 2) - padding)

    setupLines()
    trackNetwork()
  }

  func setupLines() {
    var i = 0

    for line in lines {
      line.fontColor = .white
      line.fontSize = 14
      line.fontName = "Consolas"
      line.horizontalAlignmentMode = .left
      line.verticalAlignmentMode = .top
      line.move(toParent: self)

      let y = -(line.frame.height + padding) * CGFloat(i)
      line.position = CGPoint(x: 0, y: y)

      i += 1
    }
  }

  // MARK: Game loops

  func trackNetwork() {
    if let tracker = tracker {
      let stats =
        tracker.getReceivedWithinLast(seconds: intervalSeconds).getStats()

      lines[0].text =
        "Requests: \(stats.count.formatted())"
      lines[1].text =
        "Range: \(stats.smallest.formatted()) \(stats.largest.formatted())"
      lines[2].text =
        "Mean bytes: \(stats.meanBytes.formatted())"
      lines[3].text =
        "Median bytes: \(stats.medianBytes.formatted())"
    }

    run(SKAction.wait(forDuration: intervalSeconds)) { [ weak self ] in
      self?.trackNetwork()
    }
  }
}
