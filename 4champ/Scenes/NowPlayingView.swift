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
  @IBOutlet weak var saveButton: UIButton?
  @IBOutlet weak var faveButton: UIButton?
  
  func setModule(_ module:MMD) {
    titleLabel?.text = "\(module.name!) (\(module.type!))"
    composerLabel?.text = module.composer!
    saveButton?.isSelected = module.hasBeenSaved()
    faveButton?.isSelected = module.favorite
  }
}
