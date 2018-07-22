//
//  ModulePlayer.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation

enum PlayerStatus:Int {
  case initialised
  case stopped
  case playing
  case paused
}

protocol ModulePlayerObserver: class {
  func statusChanged(status: PlayerStatus)
  func moduleChanged(module: MMD)
}

class ModulePlayer: NSObject, ReplayStreamDelegate {
  var playlist: [MMD] = []
  let renderer = Replay()

  var currentModule: MMD? {
    didSet {
      if let mod = currentModule {
        _ = observers.map {
          $0.moduleChanged(module: mod)
        }
      }
    }
  }
  var status: PlayerStatus = .initialised {
    didSet {
      _ = observers.map {
        $0.statusChanged(status: status)
      }
    }
  }
  private var observers: [ModulePlayerObserver] = []
  
  override init() {
    super.init()
    renderer.initAudio()
    renderer.streamDelegate = self
  }
  
  func addPlayerObserver(_ observer: ModulePlayerObserver) {
    observers.append(observer)
  }
  
  func removePlayerObserver(_ observer: ModulePlayerObserver) {
    if let index = observers.index(where: { mp -> Bool in
      return mp === observer
    }) {
      observers.remove(at: index)
    }
  }
  
  func play(at: Int) {
    guard at < playlist.count, let path = playlist[at].localPath?.path else {
      return
    }
    renderer.stop()
    renderer.loadModule(path)
    currentModule = playlist[at]
    renderer.play()
    status = .playing
  }
  
  func playNext() {
    guard let current = currentModule, playlist.count > 0 else {
      return
    }
    var nextIndex = 0
    if let index = playlist.index(of: current) {
      nextIndex = index + 1 % playlist.count
    }
    play(at: nextIndex)
  }
  
  func playPrev() {
  }
  
  func pause() {
    renderer.pause()
    status = .paused
  }
  
  func resume() {
    renderer.resume()
    status = .playing
  }
  
  func stop() {
    renderer.stop()
    status = .stopped
  }
  
  func reachedEnd(ofStream replay: Replay!) {
    DispatchQueue.main.async {
      self.playNext()
    }
  }
}
