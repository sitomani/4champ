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
  @IBOutlet weak var shareButton: UIButton?
  
  func setModule(_ module:MMD) {
    titleLabel?.text = "\(module.name!) (\(module.type!))"
    composerLabel?.text = module.composer!
    saveButton?.isHidden = module.hasBeenSaved()
    faveButton?.isSelected = module.favorite
    // For now, hide the share button (sharing through the long-tap menu)
    shareButton?.isHidden = true
  }
}
