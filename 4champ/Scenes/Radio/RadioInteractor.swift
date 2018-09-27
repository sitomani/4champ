//
//  RadioInteractor.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import Alamofire
import Gzip

protocol RadioBusinessLogic
{
  func controlRadio(request: Radio.Control.Request)
  func updateLatest()
  func playNext()
}

protocol RadioDataStore
{
  var channel: RadioChannel { get set }
  var status: RadioStatus { get set }
}

class RadioInteractor: NSObject, RadioBusinessLogic, RadioDataStore
{
  var presenter: RadioPresentationLogic?
  //var name: String = ""
  
  private var latestId: Int = 140000
  private var latestPlayed: Int = 0
  private var bufferLen = 3
  
  private var activeRequest: Alamofire.DataRequest?
  private var playbackTimer: Timer?

  var channel: RadioChannel = .all
  var status: RadioStatus = .off {
    didSet {
      presenter?.presentControlStatus(status: status)
    }
  }
  
  // MARK: Request handling
  func controlRadio(request: Radio.Control.Request) {
    log.debug(request)
    stopPlayback()
    guard request.powerOn == true else {
      return
    }
    UIApplication.shared.beginReceivingRemoteControlEvents()

    modulePlayer.addPlayerObserver(self)
    playbackTimer?.invalidate()
    playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.periodicUpdate()
    }
    channel = request.channel
    status = .on
    fillBuffer()
  }
  
  func updateLatest() {
    log.debug("")
    triggerBufferPresentation()
    let req = RESTRoutes.latestId
    activeRequest = Alamofire.request(req).validate().responseString { resp in
      if let value = resp.result.value, let intValue = Int(value) {
        self.latestId = intValue
      }
    }
  }
  
  func playNext() {
    log.debug("")
    switch status {
    case .off:
      return
    default:
      if modulePlayer.playlist.count == 0 { return }
    }
    modulePlayer.playNext()
  }
  
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
  
  private func triggerBufferPresentation() {
    log.debug("")
    DispatchQueue.main.async {
      self.presenter?.presentChannelBuffer(buffer: modulePlayer.playlist)
    }
  }
  private func removeBufferHead() {
    log.debug("")
    let current = modulePlayer.playlist.removeFirst()
    if let url = current.localPath {
      log.info("Deleting module \(url.lastPathComponent)")
      try! FileManager.default.removeItem(at: url)
    }
  }
  
  private func fillBuffer() {
    log.debug("buffer length \(modulePlayer.playlist.count)")
    if bufferLen > modulePlayer.playlist.count {
      let id = getNextModuleId()
      
      let fetcher = ModuleFetcher.init(delegate: self)
      fetcher.fetchModule(ampId: id)
    }
  }
  
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
    default:
      fatalError("other channels not implemented yet")
    }
  }
  
  private func gzipInflate(data: Data) -> Data? {
    if data.isGzipped {
      let inflated = try! data.gunzipped()
      return inflated
    }
    debugPrint("FAILED TO UNZIP")
    return data
  }

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
    case .failed:
      status = .failure
      
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
      
    default:
      log.debug(state)
    }
  }
}

// Delegate for getting notified about stream ending in replayer
extension RadioInteractor: ModulePlayerObserver {
  func moduleChanged(module: MMD) {
    log.debug("")
    if let index = modulePlayer.playlist.index(of: module), index > 0 {
      removeBufferHead()
    }
    fillBuffer()
    triggerBufferPresentation()
  }
  
  func statusChanged(status: PlayerStatus) {
    
  }
}
