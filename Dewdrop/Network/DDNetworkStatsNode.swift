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
  let padding = 4

  // MARK: Initialisation

  func start() {
    setupLines()
    trackNetwork()
  }

  func setupLines() {
    var i = 0

    for line in lines {
      line.move(toParent: self)
      let y = (line.frame.height + CGFloat(padding)) * CGFloat(i)
      line.position = CGPoint(x: 0, y: y)

      i += 1
    }
  }

  // MARK: Game loops

  func trackNetwork() {
    if let tracker = tracker {
      let stats =
        tracker.getReceivedWithinLast(seconds: intervalSeconds).getStats()

      lines[0].text = "Requests: \(stats.count)"
      lines[1].text = "Largest: \(stats.largest)"
      lines[1].text = "Mean bytes: \(stats.meanBytes)"
      lines[1].text = "Median bytes: \(stats.meanBytes)"
    }

    run(SKAction.wait(forDuration: intervalSeconds)) { [ weak self ] in
      self?.trackNetwork()
    }
  }
}
