//
//  ModulePlayer.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import MediaPlayer

enum PlayerError: Error {
  case loadFailed(mmd: MMD)
  case unknown
}

/// possible states of a ModulePlayer
enum PlayerStatus:Int {
  case initialised
  case stopped
  case playing
  case paused
}

enum QueueChange: Int {
  case newPlaylist
  case other
}

enum SampleInterpolation: Int {
  case libraryDefault = 0
  case off = 1
  case linear = 2
  case cubic = 4
  case windowed = 8
}

/**
 Module Player observer delegate protocol.
 Note that there can be multiple observers for the player
 */
protocol ModulePlayerObserver: class {
  /// called when player state changes (e.g. play/pause)
  /// - parameters:
  ///    - status: new status
  func statusChanged(status: PlayerStatus)

  /// called when module changes in the player
  /// - parameters:
  ///     - module: module that player changed to
  func moduleChanged(module: MMD, previous: MMD?)
  
  /// called if there is an error in the modulePlayer
  /// - parameters:
  ///    - error: Error that occurred
  func errorOccurred(error: PlayerError)
  
  /// called when play queue changes (e.g. due to playlist change, or when modules are added to queue by user)
  func queueChanged(changeType:QueueChange)
}

class ModulePlayer: NSObject {
  var radioOn: Bool = false
  var playQueue: [MMD] = [] 
  let renderer = Replay()
  let mpImage = UIImage.init(named: "albumart")!
  weak var radioRemoteControl: RadioRemoteControl?
    
  var currentModule: MMD? {
    // on currentModule change, post info on MPNowPlayingInfoCenter
    didSet {
      if let mod = currentModule {
        let author = mod.composer
        let songName = mod.name!
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
          $0.moduleChanged(module: mod, previous: oldValue)
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
    moduleStorage.addStorageObserver(self) //listen to metadata changes
    
    renderer.initAudio()
    renderer.streamDelegate = self
    let settings = SettingsInteractor()
    renderer.setStereoSeparation(settings.stereoSeparation)
    renderer.setInterpolationFilterLength(settings.interpolation.rawValue)
    NotificationCenter.default.addObserver(self,
                                   selector: #selector(handleRouteChange),
                                   name: AVAudioSession.routeChangeNotification,
                                   object: nil)
    
  }
  
  /// Adds an status change observer to ModulePlayer. Object registering as observer
  /// must also remove itself from observer list when no longer needing the callbacks
  /// - parameters:
  ///    - observer: Object implementing ModulePlayerObserver` protocol
  func addPlayerObserver(_ observer: ModulePlayerObserver) {
    observers.append(observer)
  }
  
  /// Removes an observer from the player
  /// - parameters:
  ///    - observer: Object implementing ModulePlayerObserver` protocol
  func removePlayerObserver(_ observer: ModulePlayerObserver) {
    if let index = observers.firstIndex(where: { mp -> Bool in
      return mp === observer
    }) {
      observers.remove(at: index)
    }
  }
  
  /// Starts playing a module immediately. If there are modules in play queue,
  /// the given module `mmd` will be inserted to queue at the position of currently
  /// playing module.
  /// - parameters:
  ///    - mmd: Module metadata object identifying the module to play
  func play(mmd: MMD) {
    if let mod = currentModule, var index = playQueue.firstIndex(of: mod) {
      guard mod != mmd else {
        // This is a restart of play for a module, don't mess with playlist
        play(at: index)
        return
      }
      if playQueue.count > (index + 1) {
        index += 1
      }
      playQueue.insert(mmd, at: index)
      play(at: index)
    } else {
      playQueue.append(mmd)
      play(at: playQueue.count-1)
    }
  }
  
  /// Plays a module in the play queue at given position
  /// - parameters:
  ///    - at: index of the module to play in the playlist.
  ///          Invalid index will result in no change in playback.
  @discardableResult func play(at: Int) -> Bool {
    guard at < playQueue.count, let path = playQueue[at].localPath?.path else {
      return false
    }
    renderer.stop()
    let mod = playQueue[at]
    if renderer.loadModule(path, type:mod.type) {
        let settings = SettingsInteractor()
        setStereoSeparation(settings.stereoSeparation)
        setInterpolation(settings.interpolation)
        currentModule = mod
        renderer.play()
        status = .playing
        return true
    } else {
      log.error("Could not load tune: \(path)")
        _ = observers.map {
          $0.errorOccurred(error: .loadFailed(mmd: playQueue[at]))
        }
      return false
    }
  }
  
  func setStereoSeparation(_ separation: Int) {
    var newValue = separation
    if separation < 0 || separation > 100 {
      log.warning("Separation out of bounds, using default value")
      newValue = Constants.stereoSeparationDefault
    }
    renderer.setStereoSeparation(newValue)
  }
  
  func setInterpolation(_ interpolation: SampleInterpolation) {
    renderer.setInterpolationFilterLength(interpolation.rawValue)
  }
  
  /// Set new play queue (when user selects a playlist and starts playing)
  func setNewPlayQueue(queue: [MMD]) {
    cleanup()
    playQueue = queue
    _ = observers.map {
      $0.queueChanged(changeType: .newPlaylist)
    }
  }
  
  /// Plays the next module in the current playlist. If there are no more modules,
  /// the playback will wrap to the first module in the playlist
  func playNext() {
    guard let current = currentModule, playQueue.count > 0 else {
      modulePlayer.stop()
      return
    }
    var nextIndex = 0
    if let index = playQueue.firstIndex(of: current) {
      nextIndex = (index + 1) % playQueue.count
    }
    // make sure we can move on in playlist even if there's same mod multiple times
    while playQueue[nextIndex] == currentModule && nextIndex < playQueue.count-1 {
      nextIndex += 1
    }
    if play(at: nextIndex) == false {
      playQueue.remove(at: nextIndex)
    }
  }
  
  /// Plays the previous module in the current playlist. The playlist index
  /// will not wrap from start to end when using `playPrev()` function.
  /// Function has custom implementation for Radio mode.
  func playPrev() {
    guard !radioOn else {
      radioRemoteControl?.playPrev()
      return;
    }
    guard let current = currentModule, playQueue.count > 0 else {
      return
    }
        
    var prevIndex = 0
    if let index = playQueue.firstIndex(of: current) {
      if index > 0 {
        prevIndex = index - 1
      }
    }
    play(at: prevIndex)
  }
    
  /// Pauses the current playback
  func pause() {
    guard status == .playing else { return }
    renderer.pause()
    status = .paused
  }
  
  /// Resumes paused module
  func resume() {
    guard status == .paused else { return }
    renderer.resume()
    status = .playing
  }
  
  /// Stops playback. This will also reset the now playing info
  func stop() {
    renderer.stop()
    status = .stopped
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }
  
  /// called when app resigns to clear non-stored modules
  func cleanup() {
    for mod in playQueue {
      if mod.hasBeenSaved() == false {
        if let url = mod.localPath {
          log.info("Deleting module \(url.lastPathComponent)")
          do {
            try FileManager.default.removeItem(at: url)
          } catch {
            log.error("Deleting file at \(url) failed, \(error)")
          }
        }
      }
    }
    playQueue.removeAll()
    currentModule = nil
  }

  
  /// Handle audio route change notifications
  @objc func handleRouteChange(notification: Notification) {
    log.debug("")
    guard let userInfo = notification.userInfo,
      let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
      let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
        return
    }
    
    // Pause current playback if user unplugs headphones
    switch reason {
    case .oldDeviceUnavailable:
      if let previousRoute =
        userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
        for output in previousRoute.outputs where output.portType.rawValue == AVAudioSession.Port.headphones.rawValue {
          log.info("User disconnected headphones")
          pause()
          break
        }
      }
    default: ()
    }
  }
}

extension ModulePlayer: ReplayStreamDelegate {
  func reachedEnd(ofStream replay: Replay!) {
    log.debug("")
    DispatchQueue.main.async {
      self.playNext()
    }
  }
}

extension ModulePlayer: ModuleStorageObserver {  
  // At metadata change, update currentMod and playlist MMD instances
  // for favorite status update
  func metadataChange(_ mmd: MMD) {
    if currentModule == mmd {
      currentModule?.favorite = mmd.favorite
    }
    if playQueue.count == 0 { return }
    for i in 0...playQueue.count-1 {
      if playQueue[i] == mmd {
        playQueue[i].favorite = mmd.favorite
      }
    }
    _ = observers.map {
      $0.queueChanged(changeType: .other)
    }
  }
  
  // At playlist change, load the new queue and start playing
  func playlistChange() {
    // Cleanup current queue first
//    if let pl = moduleStorage.currentPlaylist, let plMods = pl.modules {
//      cleanup()
//      for item in plMods {
//        if let mod = item as? ModuleInfo {
//          playQueue.append(MMD(cdi: mod))
//        }
//      }
//      _ = observers.map {
//        $0.queueChanged()
//      }
//
//      let shuffle = (pl.playmode?.intValue ?? 0) == 1
//      if shuffle {
//        playQueue.shuffle()
//      }
//      play(at: 0)
//    }
//
//    _ = observers.map {
//      $0.queueChanged()
//    }
  }
}
