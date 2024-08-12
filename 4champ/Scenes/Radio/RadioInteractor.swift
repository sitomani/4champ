//
//  RadioInteractor.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import Alamofire
import UserNotifications

/// Radio Interactor business logic protocol
protocol RadioBusinessLogic {
  /// Radio on/off/channel switch control interface
  /// - parameters:
  ///   - request: Control parameters (on/off/channel) in a `Radio.Control.Request` struct
  func controlRadio(request: Radio.Control.Request)

  /// Set current playing song favorite status
  func toggleFavorite()

  /// Skips current module and starts playing the next one
  func playNext()

  /// Goes back in current radio session history to previous tune
  /// May trigger re-fetch for a module
  func playPrev()

  /// Refresh the new module notifications status
  func refreshLocalNotificationsStatus()

  /// Request local notifications
  func requestLocalNotifications()

  /// Refresh badge
  func refreshBadge()

  /// Trigger save for current module
  func saveCurrentModule()

  /// Trigger share for current module
  func shareCurrentModule()

  /// Get number of modules in play queue + radio session history
  func getSessionLength() -> Int

  /// Get a given module in the session.
  func getModule(at: IndexPath) -> MMD?

  /// Play a module from session history (play queue will not be touched)
  /// - parameters:
  ///    - at: Specifies indexpath (=> row) in session history
  func playFromSessionHistory(at: IndexPath)

  /// Append the given selection to current custom channel
  /// If custom channel is not on, calling this will turn on the custom channel with the selection
  /// - parameters:
  ///     - customSelection: The selection of mods to append
  func appendSelection(_ selection: Radio.CustomSelection)
}

/// Protocol to handle play history in radio mode + start artist radio
protocol RadioRemoteControl: NSObjectProtocol {
  func playPrev()
  func controlRadio(request: Radio.Control.Request)
  func appendSelection(_ selection: Radio.CustomSelection)
}

/// Radio datastore for keeping currently selected channel and status
protocol RadioDataStore {
  var channel: RadioChannel { get }
  var status: RadioStatus { get }
  var customSelection: Radio.CustomSelection { get }
}

enum PostFetchAction {
  case appendToQueue // default
  case insertToQueue // when backstepping to session history
  case startPlay     // when selecting tune from session history
}

class RadioInteractor: NSObject, RadioBusinessLogic, RadioDataStore, RadioRemoteControl {

  var presenter: RadioPresentationLogic?

  private var lastPlayed: Int = 0 // identifier of the last module id played (used in New channel)
  private var postFetchAction: PostFetchAction = .appendToQueue // determines how to handle module at fetch complete
  private var ntfAuthorization: UNAuthorizationStatus = .notDetermined
  private var activeRequest: Alamofire.DataRequest?
  private var playbackTimer: Timer?
  private var artistRadioIndex = 0 // index of module in artist radio
  private var artistRadioIds: [Int] = []
  var customSelection: Radio.CustomSelection = Radio.CustomSelection(name: "", ids: [])

  // Keep session history for getting back to modules listened in the radio mode.
  private var radioSessionHistory: [MMD] = []

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
    NotificationCenter.default.addObserver(self, selector: #selector(doBadgeUpdate(_:)), name: Notifications.badgeUpdate, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshLocalNotificationsStatus),
                                           name: UIApplication.willEnterForegroundNotification, object: nil)
    modulePlayer.radioRemoteControl = self
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc func doBadgeUpdate(_ notification: Notification?) {
    self.presenter?.presentNewModules(response: Radio.NewModules.Response(badgeValue: settings.badgeCount))
  }

  // MARK: Request handling
  func appendSelection(_ selection: Radio.CustomSelection) {
    switch channel {
    case .selection:
      let combined = customSelection.ids + selection.ids
      self.customSelection = Radio.CustomSelection(name: self.customSelection.name, ids: combined.shuffled())
      if radioOn {
        break
      }
    default:
      controlRadio(request: Radio.Control.Request(state: .on, channel: .selection, selection: customSelection))
    }
  }

  func controlRadio(request: Radio.Control.Request) {
    log.debug(request)

    if modulePlayer.radioOn || request.state == .on {
      stopPlayback()
    }
    guard [Radio.Control.State.on, Radio.Control.State.append].contains(request.state) else {
      modulePlayer.removePlayerObserver(self)
      // modulePlayer.radioRemoteControl = nil

      presenter?.presentChannelBuffer(buffer: [], history: [])
      modulePlayer.cleanup()
      radioSessionHistory.removeAll()
      return
    }

    modulePlayer.addPlayerObserver(self)
    modulePlayer.cleanup()
    radioSessionHistory.removeAll()

    playbackTimer?.invalidate()
    playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.periodicUpdate()
    }
    if let selection = request.selection {
      if request.state == .append {
        let combined = Array(Set(customSelection.ids + selection.ids))
        customSelection = Radio.CustomSelection(name: self.customSelection.name, ids: combined.shuffled())
      } else {
        customSelection = selection
      }
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

  func playNext() {
    guard radioOn && modulePlayer.playQueue.count > 0 else { return }
    modulePlayer.playNext()
  }

  func playPrev() {
    guard radioOn && radioSessionHistory.count > 0, let currentMod = modulePlayer.currentModule else { return }

    var nextIndex = 0
    if let currentIndex = radioSessionHistory.index(of: currentMod), currentIndex >= 0 {
      nextIndex = currentIndex + 1
    }
    if radioSessionHistory.count > nextIndex, let prevId = radioSessionHistory[nextIndex].id {
      postFetchAction = .insertToQueue
      let fetcher = ModuleFetcher.init(delegate: self)
      fetcher.fetchModule(ampId: prevId)
    }
  }

  func playFromSessionHistory(at: IndexPath) {
    let historyIndex = at.row
    let mod = radioSessionHistory[historyIndex]
    if mod.fileExists() {
      modulePlayer.play(mmd: mod)
      return
    }
    guard mod.serviceId == .amp else {
      radioSessionHistory.remove(at: historyIndex)
      return
    }
    postFetchAction = .startPlay
    let fetcher = ModuleFetcher.init(delegate: self)
    fetcher.fetchModule(ampId: radioSessionHistory[historyIndex].id!)
  }

  func addToSessionHistory(module: MMD) {
    if !radioSessionHistory.contains(module) {
      radioSessionHistory.insert(module, at: 0)
      presenter?.presentSessionHistoryInsert()
    }
  }

  @objc func refreshLocalNotificationsStatus() {
    log.debug("")
    let un = UNUserNotificationCenter.current()
    un.getNotificationSettings { (settings) in
      self.ntfAuthorization = settings.authorizationStatus
      let response = Radio.LocalNotifications.Response(
        notificationsEnabled: self.ntfAuthorization == .authorized,
        notificationsRequested: self.ntfAuthorization != .notDetermined)
      self.presenter?.presentNotificationStatus(response: response)
    }
  }

  func requestLocalNotifications() {
    if self.ntfAuthorization == .authorized || self.ntfAuthorization == .denied {
      UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
      return
    }

    let un = UNUserNotificationCenter.current()
    un.requestAuthorization(options: [.badge, .sound, .alert]) { (_, _) in
      self.refreshLocalNotificationsStatus()
    }
  }

  func refreshBadge() {
    log.debug("")
    doBadgeUpdate(nil)
  }

  func shareCurrentModule() {
    guard radioOn, let mod = modulePlayer.currentModule else {
      return
    }
    shareUtil.shareMod(mod: mod)
  }

  func saveCurrentModule() {
    guard radioOn, let mod = modulePlayer.currentModule else {
      return
    }
    moduleStorage.addModule(module: mod)
  }

  func getSessionLength() -> Int {
    return radioSessionHistory.count
  }

  func getModule(at: IndexPath) -> MMD? {
    guard radioSessionHistory.count > at.row else { return nil }
    return radioSessionHistory[at.row]
  }

  // MARK: private functions

  /// Stops current playback when radio is turned off, or channel is changed
  private func stopPlayback() {
    log.debug("")
    playbackTimer?.invalidate()

    AF.session.getAllTasks { (tasks) in
      tasks.forEach {
        if !$0.currentRequest!.url!.absoluteString.contains("get_latest") {
          $0.cancel()
        }
      }
    }

    status = .off
    lastPlayed = 0
    while modulePlayer.playQueue.count > 0 {
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
      self.presenter?.presentChannelBuffer(buffer: [], history: [])
      return
    }
    self.presenter?.presentChannelBuffer(buffer: modulePlayer.playQueue, history: radioSessionHistory)
  }

  /// Removes the first module in current playlist and deletes the related local file
  private func removeBufferHead() {
    log.debug("")
    let current = modulePlayer.playQueue.removeFirst()

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
    log.debug("buffer length \(modulePlayer.playQueue.count)")
    if Constants.radioBufferLen > modulePlayer.playQueue.count {
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
      var id: Int = 0
      while(id == 0 || !radioSessionHistory.filter({ mmd in
        mmd.id == id
      }).isEmpty) {
        id = Int.random(in: 1...settings.collectionSize)
      }
      return id
    case .new:
      if lastPlayed == 0 {
        lastPlayed = settings.collectionSize
        settings.newestPlayed = lastPlayed
      } else {
        lastPlayed -= 1
      }
      return lastPlayed
    case .local:
      guard let mod = moduleStorage.getRandomModule() else {
        presenter?.presentControlStatus(status: .noModulesAvailable)
        return -1
      }
      return mod.id!
    case .selection:
      guard customSelection.ids.count > 0 else {
        presenter?.presentControlStatus(status: .noSelectionAvailable)
        return -1
      }
      let ids = customSelection.ids
      artistRadioIndex = (artistRadioIndex + 1) % ids.count
      return ids[artistRadioIndex]
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
          // keep on loading mods
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
      handleDownloadComplete(mmd)

    default: ()
    }
  }

  func handleDownloadComplete(_ mmd: MMD) {
    switch postFetchAction {
    case .appendToQueue:
      modulePlayer.playQueue.append(mmd)
    case .insertToQueue:
      modulePlayer.playQueue.insert(mmd, at: 0)
    case .startPlay:
      modulePlayer.play(mmd: mmd)
    }
    postFetchAction = .appendToQueue // reset to default

    self.triggerBufferPresentation()
    if let first = modulePlayer.playQueue.first, first == mmd {
      modulePlayer.play(at: 0)
    }
    self.fillBuffer()
    self.status = .on
  }
}

extension RadioInteractor: ModulePlayerObserver {
  func moduleChanged(module: MMD, previous: MMD?) {
    guard radioOn else { return }
    log.debug("")
    if let index = modulePlayer.playQueue.firstIndex(of: module), index > 0 {
      removeBufferHead()
    }
    fillBuffer()
    triggerBufferPresentation()
    if let previous = previous {
      addToSessionHistory(module: previous)
    }
    presenter?.presentReplayer(name: modulePlayer.renderer.name)
  }

  func statusChanged(status: PlayerStatus) {
    // nop at the moment
  }

  func errorOccurred(error: PlayerError) {
    // Skip to next mod.
    guard radioOn else { return }

    removeBufferHead()
    fillBuffer()

    switch error {
    case .loadFailed(let mmd):
      modulePlayer.playQueue.removeAll(where: { $0.id == mmd.id })
    default:
      log.error("Unknown error occurred")
    }

    playNext()
  }

  func queueChanged(changeType: QueueChange) {
    if changeType == .newPlaylist && radioOn {
      status = .off
      radioSessionHistory.removeAll()
      modulePlayer.removePlayerObserver(self)
      presenter?.presentChannelBuffer(buffer: [], history: [])
      presenter?.presentControlStatus(status: .off)
      playbackTimer?.invalidate()
    } else {
      triggerBufferPresentation()
    }
  }
}
