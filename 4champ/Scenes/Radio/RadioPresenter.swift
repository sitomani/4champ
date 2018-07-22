//
//  RadioPresenter.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import MediaPlayer

protocol RadioPresentationLogic
{
  func presentControlStatus(status: RadioStatus)
  func presentChannelBuffer(buffer: [MMD])
  func presentPlaybackTime(length: Int, elapsed: Int)
}

class RadioPresenter: RadioPresentationLogic
{
  weak var viewController: RadioDisplayLogic?
  
  // MARK: Do something
  func presentControlStatus(status: RadioStatus) {
    let vm = Radio.Control.ViewModel(status: status)
    DispatchQueue.main.async {
      self.viewController?.displayControlStatus(viewModel: vm)
    }
  }
  
  func presentChannelBuffer(buffer: [MMD]) {
    log.debug("")
    var nextUp: String?
    if buffer.count > 1 {
      nextUp = String.init(format: "Radio_NextUp".l13n(), buffer[1].name!, buffer[1].composer! )
    }
    
    let vm = Radio.ChannelBuffer.ViewModel(nowPlaying: buffer.first, nextUp: nextUp)
    DispatchQueue.main.async {
      self.viewController?.displayChannelBuffer(viewModel: vm)
    }
    
    if let currentMod = buffer.first {
      let infos = MPNowPlayingInfoCenter.default()
      let author = currentMod.composer
      let songName = String.init(format: "LockScreen_Playing".l13n(), currentMod.name!, currentMod.composer!)
      let playlistName = "LockScreen_Radio".l13n()
      
      let dict: [String: Any] =
      [ MPMediaItemPropertyAlbumTitle: playlistName,
        MPMediaItemPropertyTitle: songName,
        MPMediaItemPropertyArtist: author ?? "",
        MPMediaItemPropertyPlaybackDuration: NSNumber.init(value: modulePlayer.renderer.moduleLength()),
        MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber.init(value: modulePlayer.renderer.currentPosition())
      ]
      infos.nowPlayingInfo = dict
    }
  }
  
  func presentPlaybackTime(length: Int, elapsed: Int) {
    let timeLeft = length - elapsed
    let seconds = timeLeft % 60
    let minutes = (timeLeft - seconds) / 60
    let timeString = String.init(format: "%d:%02d", minutes, seconds)
    let vm = Radio.Playback.ViewModel(timeLeft: timeString)
    DispatchQueue.main.async {
      self.viewController?.displayPlaybackTime(viewModel: vm)
    }
  }
}
