//
//  DDSceneEffect.swift
//  Dewdrop
//
//  Created by Logan Moore on 5/4/23.
//

import Foundation
import SpriteKit

protocol DDSceneEffect: DDSceneAddable, SKNode {
  func start()
  
  func stop()
}
