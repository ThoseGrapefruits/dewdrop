//
//  DDSceneEffect.swift
//  Dewdrop
//
//  Created by Logan Moore on 5/4/23.
//

import Foundation

protocol DDSceneEffect {
  init(scene: DDScene)
  
  func start()
  
  func stop()
}
