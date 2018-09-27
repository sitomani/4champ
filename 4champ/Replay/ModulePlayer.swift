//
//  ModulePlayer.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import MediaPlayer

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
  let mpImage = UIImage.init(named: "albumart")!
  
  var currentModule: MMD? {
    didSet {
      if let mod = currentModule {
        let author = mod.composer
        let songName = String.init(format: "LockScreen_Playing".l13n(), mod.name!, mod.composer!)
        let playlistName = "LockScreen_Radio".l13n()
        
        let artwork = MPMediaItemArtwork.init(boundsSize: mpImage.size, requestHandler: { (size) -> UIImage in
          return self.mpImage
        })
        
        let dict: [String: Any] =
          [ MPMediaItemPropertyArtwork: artwork,
            MPMediaItemPropertyAlbumTitle: playlistName,
            MPMediaItemPropertyTitle: songName,
            MPMediaItemPropertyArtist: author ?? "",
            MPMediaItemPropertyPlaybackDuration: NSNumber.init(value: renderer.moduleLength()),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber.init(value: renderer.currentPosition())
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = dict
        
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
  
  func play(mmd: MMD) {
    if let mod = currentModule, var index = playlist.index(of: mod) {
      if playlist.count > (index + 1) {
        index += 1
      }
      playlist.insert(mmd, at: index)
      play(at: index)
    } else {
      playlist.append(mmd)
      play(at: playlist.count-1)
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
      nextIndex = (index + 1) % playlist.count
    }
    play(at: nextIndex)
  }
  
  func playPrev() {
  }
  
  func pause() {
    guard status == .playing else { return }
    renderer.pause()
    status = .paused
  }
  
  func resume() {
    guard status == .paused else { return }
    renderer.resume()
    status = .playing
  }
  
  func stop() {
    renderer.stop()
    status = .stopped
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }
  
  func reachedEnd(ofStream replay: Replay!) {
    DispatchQueue.main.async {
      self.playNext()
    }
  }
}
