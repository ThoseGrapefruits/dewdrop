//
//  DDNode.swift
//  Dewdrop
//
//  Created by Logan Moore on 2021-07-04.
//

import Foundation

protocol DDSceneAddable {
  /// Add self to the given `scene`
  /// - Returns: `true` if the object was sucessfully added, `false` otherwise
  func addToScene(scene: DDScene) throws -> Void
}
