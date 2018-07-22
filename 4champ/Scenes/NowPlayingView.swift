//
//  NowPlayingView.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
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
