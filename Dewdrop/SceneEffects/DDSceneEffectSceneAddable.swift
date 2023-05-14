//
//  DDSceneEffectSceneAddable.swift
//  Dewdrop
//
//  Created by Logan Moore on 5/10/23.
//

import Foundation

extension DDSceneEffect {
  func addToScene(scene: DDScene, position: CGPoint?) -> Self {
    scene.addChild(self)
    return self
  }
}
