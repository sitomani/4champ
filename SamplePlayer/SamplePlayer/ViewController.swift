//
//  ViewController.swift
//  SamplePlayer
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var modLabel: UILabel!
  
  let replay = Replay()
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    replay.initAudio()
  }
  
  @IBAction func buttonTapped(_ sender: UIButton) {
    if let btn = sender.titleLabel?.text {
      switch btn {
      case "STOP":
        modLabel.text = "no module selected"
        replay.stop()
      default:
        let mods = Bundle.main.paths(forResourcesOfType: btn.lowercased(), inDirectory: nil)
        if let mod = mods.first {
          modLabel.text = String(mod.split(separator: "/").last ?? "")
          replay.loadModule(mod)
          replay.play()
        }
      }
    }
  }
}

