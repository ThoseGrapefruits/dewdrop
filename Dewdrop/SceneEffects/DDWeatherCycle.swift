//
//  DDRainDryCycle.swift
//  Dewdrop
//
//  Created by Logan Moore on 5/4/23.
//

import Foundation
import SpriteKit

enum Cycle {
  case RAIN
  case SUN
}

class DDWeatherCycle: DDSceneEffect {
  static let WAIT_UPDATE = SKAction.wait(forDuration:  0.1);
  static let WAIT_CYCLE  = SKAction.wait(forDuration: 20);
  
  let scene: DDScene;
  
  // MARK: STATE
  
  var cycle: Cycle = .SUN;

  // MARK: DDSceneEffect

  required init(scene: DDScene) {
    self.scene = scene
  }
  
  func start() {
    runCycle()
    runTick()
  }
  
  func stop() {
    // TODO
  }

  // MARK: Runners
  
  private func runCycle() {
    switch (cycle) {
    case .RAIN: cycle = .RAIN
    case .SUN:  cycle = .RAIN
    }

    scene.run(DDWeatherCycle.WAIT_CYCLE) { [weak self] in
      self?.runCycle()
    }
  }
  
  private func runTick() {
    scene.run(DDWeatherCycle.WAIT_UPDATE) { [weak self] in
      self?.runTick()
    }
  }
}
