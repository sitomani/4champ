//
//  NowPlayingView.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 19/07/2018.
//  Copyright © 2018 boogie. All rights reserved.
//

import UIKit

class NowPlayingView: UIView {
  @IBOutlet weak var playPauseButton: UIButton?
  @IBOutlet weak var titleLabel: UILabel?
  @IBOutlet weak var composerLabel: UILabel?
  
  func setModule(_ module:MMD) {
    titleLabel?.text = "\(module.name!) (\(module.type!))"
    composerLabel?.text = module.composer!
  }
}
