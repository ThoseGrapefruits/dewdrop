//
//  DDRainDryCycle.swift
//  Dewdrop
//
//  Created by Logan Moore on 5/4/23.
//

import Foundation
import SpriteKit

enum Cycle: Equatable {
  case neutral
  case rain
  case sun
  
  case stop
}

class DDWeatherCycle: SKNode, DDSceneEffect {
  static let ACTION_SCALE_TO_0 = SKAction.scale(
    to: 0,
    duration: WAIT_DRY.duration);
  static let ACTION_DEPARENT = SKAction.removeFromParent();
  
  static let WAIT_CYCLE = SKAction.wait(forDuration: 12);
  static let WAIT_DRY   = SKAction.wait(forDuration:  1.5);
  static let WAIT_RAIN  = SKAction.wait(forDuration:  0.3);
  
  static let rng = SystemRandomNumberGenerator()
  
  // MARK: STATE
  
  var cycle: Cycle = .stop;
  var cycleNext: Cycle?;

  // MARK: DDSceneEffect
  
  func start() {
    cycle = .neutral
    cycleNext = .rain
    runCycle()
  }
  
  func stop() {
    cycle = .stop
  }

  // MARK: Runners
  
  private func runCycle() {
    print("--cycle-bef-- \(cycle) \(cycleNext)")
    
    if let cycleNext = cycleNext {
      cycle = cycleNext;
      self.cycleNext = nil
    } else {
      switch cycle {
      case .neutral:
        break;
      case .rain:
        self.applyRainUpdates()
        cycleNext = .sun
        break;
      case .sun:
        self.applySunUpdates()
        cycleNext = .rain
        break
      case .stop:
        return
      }
    }
    
    print("--cycle-aft-- \(cycle) \(cycleNext)")

    scene?.run(DDWeatherCycle.WAIT_CYCLE) { [weak self] in
      self?.runCycle()
    }
  }
  
  // MARK: API & helpers
  
  private func applyRainUpdates() {
    guard case .rain = cycle, let scene = scene as? DDScene else {
      return
    }

    let droplet = DDPlayerDroplet(circleOfRadius: DDPlayerDroplet.RADIUS);
    droplet.initPhysics()
    let xRandom = CGFloat.random(in: scene.frame.minX..<scene.frame.maxX)
    let yTop = scene.frame.maxY + 100
    scene.addChild(droplet)
    droplet.position = CGPoint(x: xRandom, y: yTop)
    
    run(DDWeatherCycle.WAIT_RAIN) { [weak self] in
      self?.applyRainUpdates()
    }
  }
  
  private func applySunUpdates(isFirstRun: Bool = true) {
    guard case .sun = cycle else {
      return
    }
    
    #if !os(iOS)
    guard let scene = scene as? DDScene else {
      return
    }
    
    if isFirstRun {
      scene.children
        .compactMap { node in node as? DDPlayerDroplet }
        .filter { droplet in droplet.owner == nil }
        .forEach { droplet in evaporate(droplet) }
    }

    scene.playerNodes
      .compactMap {
        node in node.wetChildren
          .first { wetChild in wetChild.lock == .none }
      }
      .forEach { droplet in evaporate(droplet) };

    #endif
    
    run(DDWeatherCycle.WAIT_DRY) { [weak self] in
      self?.applySunUpdates(isFirstRun: false)
    }
  }
  
  private func evaporate(_ node: DDPlayerDroplet) {
    node.lock = .evaporating
    node.run(DDWeatherCycle.ACTION_SCALE_TO_0) {
      node.lock = .none
      node.owner?.banishWetChild(wetChild: node)
      node.onRelease()
      node.removeFromParent()
    }
  }
}
