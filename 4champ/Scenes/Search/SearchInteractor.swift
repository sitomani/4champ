//
//  SearchInteractor.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import Foundation

/// Search Interactor business logic interface
protocol SearchBusinessLogic {
  /// Triggers a search towards 4champ.net
  /// - parameters:
  ///    - request: parameters for the search (keyword, type, paging index)
  func search(_ request: Search.Request)

  /// Triggers a resource list fetch based on variables set in the datastore
  func triggerAutoFetchList()

  /// Starts download and playback of a module
  /// - parameters:
  ///    - moduleId: id of the module to download
  func download(moduleId: Int)

  /// Starts download of a set of modules to persistent storage. Progress will be indicated
  /// through presentDownloadProgress
  /// - parameters:
  ///    - request: BatchDownload request containing the ids to download
  func downloadModules(_ request: Search.BatchDownload.Request)

  /// Cancels an ongoing multiple module fetch
  func cancelDownload()

  func getModuleInfo(at: IndexPath) -> ModuleInfo?

  func addToPlaylist(moduleId: Int, playlistId: String)

  func deleteModule(at indexPath: IndexPath)

  func setupRadio(_ request: Search.RadioSetup.Request)
}

/// Search Interactor datastore
protocol SearchDataStore {
  var autoListTitle: String? { get set }
  var autoListId: Int? { get set }
  var autoListType: SearchType? { get set }
  var pagingIndex: Int { get }
}

/// Implementation of Search business logic∂a
class SearchInteractor: SearchBusinessLogic, SearchDataStore {

  var presenter: SearchPresentationLogic?
  var settingsInteractor = SettingsInteractor()

  var autoListTitle: String?
  var autoListId: Int?
  var autoListType: SearchType?
  var pagingIndex: Int = 0

  private var currentTask: Task<Sendable, Error>?
  private var downloadQueue: [Int] = []
  private var favoritedModuleId: Int = 0
  private var originalQueueLenght: Int = 0
  private var fetcher: ModuleFetcher?
  private var latestModuleResponse = Search.Response<ModuleResult>(result: [], text: "")
  private var nwClient = NetworkClient()

  init() {
    moduleStorage.addStorageObserver(self)
  }

  deinit {
    moduleStorage.removeStorageObserver(self)
  }

  func search(_ request: Search.Request) {
    log.debug("keyword: \(request.text), type: \(request.type), pagingIndex: \(request.pagingIndex)")

    if currentTask != nil {
      currentTask?.cancel()
      currentTask = nil
    }

    let req: APISearchRequest = APISearchRequest(type: request.type, sought: request.text, position: request.pagingIndex)

    currentTask = Task {
      do {
        let responseData = try await nwClient.send(req)
        if false == processResponse(request: request, responseData: responseData) {
          self.latestModuleResponse = Search.Response<ModuleResult>(result: [], text: request.text)
          self.presenter?.presentSearchResponse(self.latestModuleResponse)
        }
        self.pagingIndex = request.pagingIndex
      } catch let err {
        self.latestModuleResponse = Search.Response<ModuleResult>(result: [], text: request.text)
        self.presenter?.presentSearchResponse(self.latestModuleResponse)
        log.error(String.init(describing: err))
      }
      return
    }
    return
  }

  private func processResponse(request: Search.Request, responseData: Data) -> Bool {
    switch request.type {
    case SearchType.module, SearchType.meta:
      if let modules = try? JSONDecoder().decode([ModuleResult].self, from: responseData) {
        self.latestModuleResponse = Search.Response<ModuleResult>(result: modules, text: request.text)
        self.presenter?.presentSearchResponse(self.latestModuleResponse)
        return true
      }
    case SearchType.composer:
      if let composers = try? JSONDecoder().decode([ComposerResult].self, from: responseData) {
        self.presenter?.presentSearchResponse(Search.Response<ComposerResult>(result: composers, text: request.text))
        return true
      }
    case SearchType.group:
      if let groups = try? JSONDecoder().decode([GroupResult].self, from: responseData) {
        self.presenter?.presentSearchResponse(Search.Response<GroupResult>(result: groups, text: request.text))
        return true
      }
      // fallback for the AMP response for direct group match: returns composers
      if let composers = try? JSONDecoder().decode([ComposerResult].self, from: responseData) {
        self.presenter?.presentSearchResponse(Search.Response<ComposerResult>(result: composers, text: request.text))
        return true
      }
    }
    return false
  }

  func setupRadio(_ request: Search.RadioSetup.Request) {
    // handle the text/module name search case
    let newState: Radio.Control.State = (request.appending) ? .append : .on

    let newSelection: Radio.CustomSelection

    if let selection = request.selection, selection.ids.count > 0 {
      newSelection = selection
    } else if latestModuleResponse.result.count > 0 {
      let supportedMods = latestModuleResponse.result.filter { MMD.supportedTypes.contains($0.format) }
      let modIDs = supportedMods.map { mr in
        mr.getId()
      }.shuffled()
      newSelection = Radio.CustomSelection(name: autoListTitle, ids: modIDs)
    } else {
      log.error("Attempted to start custom channel with no data")
      return
    }

    let isAppending = request.appending && modulePlayer.radioOn
    let count = modulePlayer.controlRadio(Radio.Control.Request(state: newState, channel: RadioChannel.selection, selection: newSelection))
    let response = Search.RadioSetup.Response(channelName: newSelection.name,
                                              moduleCount: count,
                                              appending: isAppending)
    presenter?.presentRadioResponse(response: response)
  }

  func triggerAutoFetchList() {
    guard let id = autoListId, let type = autoListType else { return }

    if type == .composer {
      let req = APIListModulesRequest(composerId: id)
      Task {
        if let response = try? await nwClient.send(req) {
          self.latestModuleResponse = Search.Response<ModuleResult>(result: response, text: "")
          self.presenter?.presentSearchResponse(self.latestModuleResponse)
        }
      }
    } else if type == .group {
      let req = APIListComposersRequest(groupId: id)
      Task {
        if let response = try? await nwClient.send(req) {
          self.presenter?.presentSearchResponse(Search.Response<ComposerResult>(result: response, text: ""))
        }
      }
    } else {
      log.error("Invalid type for auto fetch \(type)")
    }
  }

  func download(moduleId: Int) {
    // reset the download queue if single downloads are triggered
    originalQueueLenght = 0
    downloadQueue = []
    doDownload(moduleId: moduleId)
  }

  func getModuleInfo(at: IndexPath) -> ModuleInfo? {
    guard latestModuleResponse.result.count > at.row else {
      return nil
    }
    let msr = latestModuleResponse.sortedResult()[at.row]
    if let modInfo = moduleStorage.fetchModuleInfo(msr.getId()) {
      return modInfo
    }
    return nil
  }

  func deleteModule(at: IndexPath) {
    if let cdi = getModuleInfo(at: at) {
      var mod = MMD(cdi: cdi)
      moduleStorage.deleteModule(module: mod)
      mod.favorite = false
      mod.localPath = nil

      // Remove deleted module from play queue
      if let queueIndex = modulePlayer.playQueue.firstIndex(of: mod) {
        modulePlayer.playQueue.remove(at: queueIndex)
      }

      presenter?.presentDeletion(response: Search.MetaDataChange.Response(module: mod))
    }
  }

  private func doDownload(moduleId: Int) {
    // Always create a new fetcher. Fetchers will be released
    // Once the fetch is complete
    fetcher = ModuleFetcher.init(delegate: self)

    // First check if the mod is already downloaded to play queue => in the case, bypass fetch
    // and go directly to done state.
    if let mod = (modulePlayer.playQueue.first { $0.id == moduleId }), mod.localPath != nil, FileManager.default.fileExists(atPath: mod.localPath!.path) {
      fetcherStateChanged(fetcher!, state: .done(mmd: mod))
      return
    }

    fetcher?.fetchModule(ampId: moduleId)
  }

  func downloadModules(_ request: Search.BatchDownload.Request) {
    downloadQueue = request.moduleIds
    originalQueueLenght = request.moduleIds.count
    if request.favorite {
      favoritedModuleId = request.moduleIds.first ?? 0
    } else {
      favoritedModuleId = 0
    }
    fetchNextQueuedModule()
  }

  func cancelDownload() {
    downloadQueue = []
    fetcher?.cancel()
  }

  func addToPlaylist(moduleId: Int, playlistId: String) {

  }

  private func fetchNextQueuedModule() {
    var resp = Search.BatchDownload.Response(originalQueueLength: originalQueueLenght,
                                             queueLength: downloadQueue.count,
                                             complete: false,
                                             favoritedModuleId: favoritedModuleId)
    guard downloadQueue.count > 0 else {
      resp.complete = true
      presenter?.presentBatchProgress(response: resp)
      return
    }
    let nextId = downloadQueue.removeFirst()
    presenter?.presentBatchProgress(response: resp)
    doDownload(moduleId: nextId)
  }

}

extension SearchInteractor: ModuleFetcherDelegate {
  func fetcherStateChanged(_ fetcher: ModuleFetcher, state: FetcherState) {
    log.debug(state)
    switch state {
    case .done(var mmd):
      presenter?.presentDownloadProgress(response: Search.ProgressResponse(progress: 1.0))
      if originalQueueLenght == 0 {
        modulePlayer.play(mmd: mmd)
        // removeBufferHead()
      } else {
        if favoritedModuleId == mmd.id {
          mmd.favorite = true
        }
        moduleStorage.addModule(module: mmd)
        presenter?.presentMetadataChange(response: Search.MetaDataChange.Response(module: mmd))
        fetchNextQueuedModule()
      }
    case .downloading(let progress):
      log.debug(progress)
      presenter?.presentDownloadProgress(response: Search.ProgressResponse(progress: progress))
    case .failed(let err):
      log.error(err.debugDescription)
      if downloadQueue.count == 0 {
        presenter?.presentDownloadProgress(response: Search.ProgressResponse(progress: 0, error: err))
      }
      fetchNextQueuedModule()
    default:
      log.debug("noop")
    }
  }

  /// Keeps the playlist short so that the disk is not flooded with modules
  private func removeBufferHead() {
    guard modulePlayer.playQueue.count > Constants.radioBufferLen else { return }
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
}

extension SearchInteractor: ModuleStorageObserver {
  func metadataChange(_ mmd: MMD) {
    presenter?.presentMetadataChange(response: Search.MetaDataChange.Response(module: mmd))
    log.debug("")
  }

  func playlistChange() {
    log.debug("")
  }
}
