//
//  RadioInteractor.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import Alamofire


/// Radio Interactor business logic protocol
protocol RadioBusinessLogic
{
  /// Radio on/off/channel switch control interface
  /// - parameters:
  ///   - request: Control parameters (on/off/channel) in a `Radio.Control.Request` struct
  func controlRadio(request: Radio.Control.Request)
  
  /// Set current playing song favorite status
  func toggleFavorite()
  
  /// Updates the most recently added module id by querying 4champ.net REST interface
  /// called currently only once when radio view is displayed the first time in a session.
  func updateLatest()
  
  /// Skips current module and starts playing the next one
  func playNext()
}

/// Radio datastore for keeping currently selected channel and status
protocol RadioDataStore
{
  var channel: RadioChannel { get set }
  var status: RadioStatus { get set }
}

class RadioInteractor: NSObject, RadioBusinessLogic, RadioDataStore
{
  var presenter: RadioPresentationLogic?
  
  private var latestId: Int = 152506 // latest id in the AMP database (updated when NEW channel used)
  private var latestPlayed: Int = 0 // identifier of the latest module id played (used in New channel)
  
  private var activeRequest: Alamofire.DataRequest?
  private var playbackTimer: Timer?

  private var radioOn: Bool {
    switch status {
    case .off:
      return false
    default:
      return true
    }
  }
  
  var channel: RadioChannel = .all
  var status: RadioStatus = .off {
    didSet {
      presenter?.presentControlStatus(status: status)
      modulePlayer.radioOn = self.radioOn
    }
  }
  
  override init() {
    super.init()
    moduleStorage.addStorageObserver(self)
  }
  
  // MARK: Request handling
  func controlRadio(request: Radio.Control.Request) {
    log.debug(request)
    stopPlayback()
    guard request.powerOn == true else {
      presenter?.presentChannelBuffer(buffer: [])
      return
    }

    modulePlayer.addPlayerObserver(self)
    playbackTimer?.invalidate()
    playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.periodicUpdate()
    }
    channel = request.channel
    status = .on
    fillBuffer()
  }
  
  func toggleFavorite() {

    guard let mod = modulePlayer.currentModule else {
      log.error("no current module => cannot toggle favorite")
      return
    }
    _ = moduleStorage.toggleFavorite(module: mod)
  }
  
  func updateLatest() {
    log.debug("")
    let req = RESTRoutes.latestId
    activeRequest = Alamofire.request(req).validate().responseString { resp in
      if let value = resp.result.value, let intValue = Int(value) {
        self.latestId = intValue
      }
    }
  }
  
  func playNext() {
    guard radioOn && modulePlayer.playlist.count > 0 else { return }
    modulePlayer.playNext()
  }
  
  // MARK: private functions
  
  /// Stops current playback when radio is turned off, or channel is changed
  private func stopPlayback() {
    log.debug("")
    UIApplication.shared.endReceivingRemoteControlEvents()
    playbackTimer?.invalidate()
    Alamofire.SessionManager.default.session.getAllTasks { (tasks) in
      tasks.forEach{ $0.cancel() }
    }
    
    status = .off
    latestPlayed = 0
    while modulePlayer.playlist.count > 0 {
      removeBufferHead()
    }
    modulePlayer.stop()
    modulePlayer.removePlayerObserver(self)
    periodicUpdate()
    triggerBufferPresentation()
  }
  
  /// Triggers current radio playlist presentation
  private func triggerBufferPresentation() {
    log.debug("")
    guard radioOn else {
      self.presenter?.presentChannelBuffer(buffer: [])
      return
    }
    self.presenter?.presentChannelBuffer(buffer: modulePlayer.playlist)
  }

  /// Removes the first module in current playlist and deletes the related local file
  private func removeBufferHead() {
    log.debug("")
    let current = modulePlayer.playlist.removeFirst()
    
    guard moduleStorage.getModuleById(current.id!) == nil else {
        // Not removing modules in local storage
        return
    }
    
    if let url = current.localPath {
      log.info("Deleting module \(url.lastPathComponent)")
      do {
        try FileManager.default.removeItem(at: url)
      } catch {
        log.error("Deleting file at \(url) failed, \(error)")
      }
    }
  }
  
  /// Fills the radio buffer as needed (called when radio is turned on
  /// and when current module changes, to keep the buffer populated
  private func fillBuffer() {
    log.debug("buffer length \(modulePlayer.playlist.count)")
    if Constants.radioBufferLen > modulePlayer.playlist.count {
      let id = getNextModuleId()
      if id < 0 { return } // failed to determine next module id
      let fetcher = ModuleFetcher.init(delegate: self)
      fetcher.fetchModule(ampId: id)
    }
  }
  
  /// Returns next module id for buffer filling based on current radio channel selection
  /// - returns: id for the next module to load into buffer
  private func getNextModuleId() -> Int {
    log.debug("")
    switch channel {
    case .all:
      let id = arc4random_uniform(UInt32(latestId))
      return Int(id)
    case .new:
      if latestPlayed == 0 {
        latestPlayed = latestId
      } else {
        latestPlayed = latestPlayed - 1
      }
      return latestPlayed
    case .local:
      guard let mod = moduleStorage.getRandomModule() else {
        presenter?.presentControlStatus(status: .noModulesAvailable)
        return -1
      }
      return mod.id!
    }
  }
  
  /// Playback time update periodic called from `playbackTimer`
  private func periodicUpdate() {
    var length = 0
    var elapsed = 0
    if modulePlayer.renderer.isPlaying {
      length = Int(modulePlayer.renderer.moduleLength())
      elapsed = Int(modulePlayer.renderer.currentPosition())
    }
    presenter?.presentPlaybackTime(length: length, elapsed: elapsed)
  }
}

extension RadioInteractor: ModuleFetcherDelegate {
  func fetcherStateChanged(_ fetcher: ModuleFetcher, state: FetcherState) {
    switch state {
    case .failed(let err):
      if let fetcherErr = err as? FetcherError {
        if fetcherErr == .unsupportedFormat {
          //keep on loading mods
          fillBuffer()
          return
        }
      }
      if radioOn {
        status = .failure
      }
    case .downloading(let progress):
      status = .fetching(progress: progress)
      
    case .done(let mmd):
      modulePlayer.playlist.append(mmd)
      self.triggerBufferPresentation()
      if let first = modulePlayer.playlist.first, first == mmd {
        modulePlayer.play(at: 0)
      }
      self.fillBuffer()
      self.status = .on
      
    default: ()
    }
  }
}

extension RadioInteractor: ModulePlayerObserver {
  func moduleChanged(module: MMD) {
    guard radioOn else { return }
    log.debug("")
    if let index = modulePlayer.playlist.firstIndex(of: module), index > 0 {
      removeBufferHead()
    }
    fillBuffer()
    triggerBufferPresentation()
  }
  
  func statusChanged(status: PlayerStatus) {
    //nop at the moment
  }
  
  func errorOccurred(error: PlayerError) {
    //nop at the moment
  }
}

extension RadioInteractor: ModuleStorageObserver {
  func metadataChange(_ mmd: MMD) {
    guard radioOn else { return }
    triggerBufferPresentation()
  }
}
