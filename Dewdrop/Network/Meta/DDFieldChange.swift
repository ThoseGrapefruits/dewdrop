//
//  DDFieldChange.swift
//  DDFieldChange
//
//  Created by Logan Moore on 2021-08-23.
//

import Foundation
import SpriteKit

enum DDFieldChange<FieldType> {

  // MARK: Operations

  case add  (FieldType)
  case set  (FieldType)

  // MARK: apply

  func apply(to existingValue: FieldType?) -> FieldType {
    switch self {
      case .add(_):
        fatalError(
          "apply(to:) .add not implemented for \( type(of: existingValue) )")
      case .set(let newValue):
        return newValue
    }
  }

  // MARK: apply - SpriteKit

  func apply(to existingValue: FieldType?)
  -> FieldType where FieldType == CGFloat {
    switch self {
      case .add(let newValue):
        return existingValue ?? 0 + newValue
      case .set(let newValue):
        return newValue
    }
  }

  func apply(to existingValue: FieldType?)
  -> FieldType where FieldType == CGPoint {
    switch self {
      case .add(let newValue):
        return CGPoint(
          x: newValue.x + (existingValue?.x ?? 0),
          y: newValue.y + (existingValue?.y ?? 0))
      case .set(let newValue):
        return newValue
    }
  }

  func apply(to existingValue: FieldType?)
  -> FieldType where FieldType == CGVector {
    switch self {
      case .add(let newValue):
        return CGVector(
          dx: newValue.dx + (existingValue?.dx ?? 0),
          dy: newValue.dy + (existingValue?.dy ?? 0))
      case .set(let newValue):
        return newValue
    }
  }
}

