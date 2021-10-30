//
//  DDGameCenterDelegate.swift
//  DDGameCenterDelegate
//
//  Created by Logan Moore on 2021-08-15.
//

import Foundation
import GameKit
import SpriteKit

enum FindMatchError {
  case cancelled
  case other(Error)
}

class DDMatchmaking : NSObject,
                  GKGameCenterControllerDelegate,
                  GKInviteEventListener,
                  GKMatchmakerViewControllerDelegate {

  // MARK: State

  var findMatchClosure:
    ((_ match: GKMatch?, _ error: FindMatchError?) -> Void)? = .none
  var matchmakerViewController: GKMatchmakerViewController? = .none

  // MARK: Game Center

  func ensureGameCenter(
    view: UIViewController,
    _ closure: @escaping () -> Void
  ) {
    GKLocalPlayer.local.authenticateHandler =
    { viewController, error in
      if error != nil {
        // Player could not be authenticated.
        return
      }

      guard let viewController = viewController else {
        return closure()
      }

      let rootViewController =
        UIApplication.shared.delegate!.window!!.rootViewController!

      rootViewController.present(viewController, animated: true)

      if GKLocalPlayer.local.isUnderage {
        // Hide explicit game content.
      }

      if GKLocalPlayer.local.isMultiplayerGamingRestricted {
        return
      }

      if GKLocalPlayer.local.isPersonalizedCommunicationRestricted {
        // Disable in-game communication UI.
      }

      return closure()
    }
  }

  func findMatch(
    view: UIViewController,
    _ closure: @escaping (_ match: GKMatch?, _ error: FindMatchError?) -> Void
  ) {
    guard findMatchClosure == nil else {
      return
    }

    findMatchClosure = closure

    ensureGameCenter(view: view) { [weak self] in
      guard let self = self else {
        return
      }

      let request = GKMatchRequest()
      request.minPlayers = 2
      request.maxPlayers = 4

      if (self.matchmakerViewController == nil) {
        self.matchmakerViewController =
          GKMatchmakerViewController(matchRequest: request)
      }

      self.matchmakerViewController!.isHosted = false  // peer-to-peer
      self.matchmakerViewController!.matchmakerDelegate = self

      view.present(self.matchmakerViewController!, animated: true)
    }
  }

  // MARK: GKGameCenterControllerDelegate

  func gameCenterViewControllerDidFinish(
    _ gameCenterViewController: GKGameCenterViewController
  ) {
    gameCenterViewController.dismiss(animated: true)
  }

  // MARK: GKMatchmarkerViewControllerDelegate

  func matchmakerViewControllerWasCancelled(
      _ viewController: GKMatchmakerViewController
  ) {
    findMatchClosure?(nil, .cancelled)
    findMatchClosure = .none;
    viewController.dismiss(animated:true)
  }

  func matchmakerViewController(
    _ viewController: GKMatchmakerViewController,
    didFailWithError error: Error
  ) {
    findMatchClosure?(nil, .other(error))
    findMatchClosure = .none
    viewController.dismiss(animated:true)
  }

  func matchmakerViewController(
    _ viewController: GKMatchmakerViewController,
    didFind match: GKMatch
  ) {
    findMatchClosure?(match, nil)
    viewController.dismiss(animated: true)
  }

  // MARK: GKInviteEventListener

  func player(_ player: GKPlayer, didAccept invite: GKInvite) {
    let viewController = GKMatchmakerViewController(invite: invite)!
    viewController.matchmakerDelegate = self
    let rootViewController =
      UIApplication.shared.delegate!.window!!.rootViewController!
    rootViewController.present(viewController, animated: true, completion: nil)
  }
}
