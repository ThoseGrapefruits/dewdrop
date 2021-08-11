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
    kProportion = Double(kP);
    kIntegral = Double(kI);
    kDerivative = Double(kD);
  }

  func step(error: CGFloat, deltaTime: TimeInterval) -> CGFloat {
    let time = deltaTime + (lastTime ?? TimeInterval.zero)

    return step(error: error, currentTime: time)
  }

  func step(error errorFloat: CGFloat, currentTime: TimeInterval) -> CGFloat {
    let error = Double(errorFloat);
    let secondsElapsed = (lastTime ?? currentTime).distance(to: currentTime);
    lastTime = currentTime;

    let errorDerivative = error - lastError;

    lastError = error;

    cProportion = error
    cIntegral += error * secondsElapsed

    cDerivative = 0
    if (secondsElapsed > 0) {
      cDerivative = errorDerivative / secondsElapsed
    }

    return CGFloat(
      (kProportion * cProportion) +
      (kIntegral   * cIntegral) +
      (kDerivative * cDerivative)
    )
  }
}
