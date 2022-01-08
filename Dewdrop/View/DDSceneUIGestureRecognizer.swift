//
//  DDSceneUIGestureRecognizer.swift
//  Dewdrop
//
//  Created by Logan Moore on 2022-01-08.
//

import Foundation
import UIKit

extension DDScene: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(
    _ gestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
  ) -> Bool {
    true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldReceive touch: UITouch
  ) -> Bool {
    print("shouldReceive touch: \( touch )")
    return touch === moveTouch
  }
}
