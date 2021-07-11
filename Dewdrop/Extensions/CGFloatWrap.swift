//
//  CGFloatWrap.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-11.
//

import Foundation
import SpriteKit

extension CGFloat {
  func wrap(around boundary: CGFloat) -> CGFloat {
    if (self > boundary) {
      return (self - boundary * 2).wrap(around: boundary)
    } else if (self < -boundary) {
      return (self + boundary * 2).wrap(around: boundary)
    } else {
      return self
    }
  }
}
