//
//  MainViewController.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol NowPlayingContainer {
  func toggleNowPlaying(_ value: Bool)
}

class MainViewController: UITabBarController {
  
  @IBOutlet weak var npView: NowPlayingView!
  
  var playingConstraint: NSLayoutConstraint?
  var notplayingConstraint: NSLayoutConstraint?
  
  override func viewDidLoad() {
    log.debug("")
    super.viewDidLoad()
    
    view.addSubview(npView)
    npView.translatesAutoresizingMaskIntoConstraints = false
    npView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    npView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    playingConstraint = npView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
    playingConstraint?.isActive = false
    notplayingConstraint = npView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    notplayingConstraint?.priority = .defaultLow
    notplayingConstraint?.isActive = true
    npView.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
    npView?.alpha = 0
    
    self.becomeFirstResponder()
    modulePlayer.addPlayerObserver(self)
    moduleStorage.addStorageObserver(self)
  }
  
  func toggleNowPlaying(_ value: Bool) {
    log.debug("")
    
    UIView.animate(withDuration: 0.15) {
      self.playingConstraint?.isActive = value
      self.npView?.alpha = CGFloat(value == true ? 1 : 0)
      self.view.layoutIfNeeded()
    }
    
    for ctl in self.children {
      if let navCtl = ctl as? UINavigationController,
        let firstChild = navCtl.topViewController as? NowPlayingContainer {
        firstChild.toggleNowPlaying(value)
      }
    }
  }
  
  override func remoteControlReceived(with event: UIEvent?) {
        guard let event = event else {
          return
        }
        switch event.subtype {
        case .remoteControlPlay:
          modulePlayer.resume()
          break
        case .remoteControlPause:
          modulePlayer.pause()
          break
        case .remoteControlStop:
          modulePlayer.stop()
          break
        case .remoteControlNextTrack:
          modulePlayer.playNext()
        case .remoteControlPreviousTrack:
          modulePlayer.playPrev()
        default:
          log.debug("remote control event \(event.subtype) not handled")
        }
  }
  
  @IBAction func togglePlay(_ sender: UIButton) {
    if modulePlayer.status == .paused {
      modulePlayer.resume()
    } else {
      modulePlayer.pause()
    }
  }
  
  @IBAction func showVisualizer(_ sender: UIButton) {
    log.debug("")
    if self.presentedViewController == nil {
      performSegue(withIdentifier: "ToVisualizer", sender: self)
    }
  }
  
  @IBAction func saveModule(_ sender: UIButton) {
    log.debug("")
    guard let mod = modulePlayer.currentModule else {
      log.error("no current module => cannot save")
      return
    }
    moduleStorage.addModule(module: mod)
    npView.setModule(mod)
  }
  
  @IBAction func faveModule(_ sender: UIButton) {
    guard let mod = modulePlayer.currentModule else {
      log.error("no current module => cannot toggle favorite")
      return
    }
    if let updated = moduleStorage.toggleFavorite(module: mod) {
      npView.setModule(updated)
    }
  }
  
}

extension MainViewController: ModulePlayerObserver {
  func moduleChanged(module: MMD) {
    log.info("\(module.name!) (\(module.type!))")
    DispatchQueue.main.async {
      self.npView.setModule(module)
    }
  }
  
  func statusChanged(status: PlayerStatus) {
    log.info("\(status)")
    DispatchQueue.main.async {
      self.toggleNowPlaying(status == .playing || status == .paused)
      self.npView.playPauseButton?.isSelected = (status == .paused)
    }
  }
  
  func errorOccurred(error: PlayerError) {
    //nop at the moment
  }
  
  func playlistChanged() {
    //nop at the moment
  }
}

extension MainViewController: ModuleStorageObserver {
  func metadataChange(_ mmd: MMD) {
    if modulePlayer.currentModule?.id == mmd.id {
      npView.setModule(mmd)
    }
  }
}
