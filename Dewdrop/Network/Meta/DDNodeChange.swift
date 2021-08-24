//
//  DDNodeChange.swift
//  DDNodeChange
//
//  Created by Logan Moore on 2021-08-23.
//

import Foundation

enum DDNodeChange : Codable {
  case delta(DDNodeDelta)
  case full(DDNodeSnapshot)
}
