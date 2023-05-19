//
//  CGRect.swift
//  Dewdrop
//
//  Created by Logan Moore on 5/18/23.
//

import Foundation

extension CGRect {
  func getCorners() -> [CGPoint] {
    return [
      CGPoint(x: minX, y: minY),
      CGPoint(x: minX, y: maxY),
      CGPoint(x: maxX, y: maxY),
      CGPoint(x: maxX, y: minY),
    ]
  }
  
  func getEdges() -> [(CGPoint, CGPoint)] {
    let corners = self.getCorners()
    let shifted = corners[1...] + corners[..<1]
    return zip(corners, shifted)
      .map { (p0, p1) in (p0, p1) }
  }
  
  func getBorderRects(ofWidth bWidth: CGFloat) -> [CGRect] {
    let ofs = bWidth / 2
    return [
      CGRect(x: minX - ofs, y: midY,       width: bWidth, height: height), // left
      CGRect(x: midX,       y: maxY + ofs, width: width,  height: bWidth), // top
      CGRect(x: maxX + ofs, y: midY,       width: bWidth, height: height), // right
      CGRect(x: midX,       y: minY - ofs, width: width,  height: bWidth), // bottom
    ]
  }
}
