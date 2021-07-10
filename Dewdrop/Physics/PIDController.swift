//
//  PIDController.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-05.
//

import Foundation
import SpriteKit

class PIDController {
  var kProportion: Double;
  var kIntegral: Double;
  var kDerivative: Double;

  var cProportion: Double = 0;
  var cIntegral: Double = 0;
  var cDerivative: Double = 0;

  var lastError: Double = 0;
  var lastTime: Optional<TimeInterval> = .none;

  init(kP: CGFloat, kI: CGFloat, kD: CGFloat) {
    self.kProportion = Double(kP);
    self.kIntegral = Double(kI);
    self.kDerivative = Double(kD);
  }

  func step(error: CGFloat, deltaTime: TimeInterval) -> CGFloat {
    let time = deltaTime + (lastTime ?? TimeInterval.zero)

    return step(error: error, currentTime: time)
  }

  func step(error: CGFloat, currentTime: TimeInterval) -> CGFloat {
    let errorDouble = Double(error);
    let secondsElapsed = currentTime.distance(to: lastTime ?? currentTime);
    self.lastTime = currentTime;

    let errorDerivative = errorDouble - self.lastError;

    self.lastError = errorDouble;

    self.cProportion = self.kProportion * errorDouble
    self.cIntegral += errorDouble * secondsElapsed

    self.cDerivative = 0
    if (secondsElapsed > 0) {
      self.cDerivative = errorDerivative / secondsElapsed
    }

    return CGFloat(
      self.cProportion +
      (self.kIntegral * self.cIntegral) +
      (self.kDerivative * self.cDerivative)
    )
  }
}
