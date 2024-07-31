//
//  SearchInteractor.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Alamofire
import Foundation
import UIKit

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

  func startArtistRadio()
}

/// Search Interactor datastore
protocol SearchDataStore {
  var autoListTitle: String? { get set }
  var autoListId: Int? { get set }
  var autoListType: SearchType? { get set }
  var pagingIndex: Int { get }
}

/// Implementation of Search business logic
class SearchInteractor: SearchBusinessLogic, SearchDataStore {
  var presenter: SearchPresentationLogic?
  var settingsInteractor = SettingsInteractor()

  var autoListTitle: String?
  var autoListId: Int?
  var autoListType: SearchType?
  var pagingIndex: Int = 0

  private var currentRequest: Alamofire.DataRequest?
  private var downloadQueue: [Int] = []
  private var favoritedModuleId: Int = 0
  private var originalQueueLenght: Int = 0
  private var fetcher: ModuleFetcher?
  private var latestModuleResponse = Search.Response<ModuleResult>(result: [], text: "")

  init() {
    moduleStorage.addStorageObserver(self)
  }

  deinit {
    moduleStorage.removeStorageObserver(self)
  }

  func search(_ request: Search.Request) {
    log.debug("keyword: \(request.text), type: \(request.type), pagingIndex: \(request.pagingIndex)")
    if currentRequest != nil {
      currentRequest?.cancel()
      currentRequest = nil
    }
    let restRequest = RESTRoutes.search(type: request.type, text: request.text, position: request.pagingIndex)
    currentRequest = AF.request(restRequest).validate().responseData { response in
      if let checkReq = self.currentRequest?.request, checkReq != response.request {
        log.warning("overlapping requests. Bypass all except most recent.")
        return
      }
      if case let .success(jsonData) = response.result {
        log.info("\(response.result) \(request.text)")
        self.pagingIndex = request.pagingIndex
        if self.processResponse(request: request, responseData: jsonData) == false {
          self.latestModuleResponse = Search.Response<ModuleResult>(result: [], text: request.text)
          self.presenter?.presentSearchResponse(self.latestModuleResponse)
        }
      } else {
        log.error(String(describing: response.error))
      }
      self.currentRequest = nil
    }
  }

  private func processResponse(request: Search.Request, responseData: Data) -> Bool {
    switch request.type {
    case SearchType.module, SearchType.meta:
      if let modules = try? JSONDecoder().decode([ModuleResult].self, from: responseData) {
        latestModuleResponse = Search.Response<ModuleResult>(result: modules, text: request.text)
        presenter?.presentSearchResponse(latestModuleResponse)
        return true
      }
    case SearchType.composer:
      if let composers = try? JSONDecoder().decode([ComposerResult].self, from: responseData) {
        presenter?.presentSearchResponse(Search.Response<ComposerResult>(result: composers, text: request.text))
        return true
      }
    case SearchType.group:
      if let groups = try? JSONDecoder().decode([GroupResult].self, from: responseData) {
        presenter?.presentSearchResponse(Search.Response<GroupResult>(result: groups, text: request.text))
        return true
      }
    }
    return false
  }

  func startArtistRadio() {
    guard latestModuleResponse.result.count > 0 else { return }
    let modIDs = latestModuleResponse.result.map { mr in
      mr.getId()
    }.shuffled()

    let channel = RadioChannel.artist(name: autoListTitle ?? "n/a", ids: modIDs)
    modulePlayer.controlRadio(Radio.Control.Request(powerOn: true, channel: channel))
  }

  func triggerAutoFetchList() {
    guard let id = autoListId, let type = autoListType else { return }

    if type == .composer {
      let restRequest = RESTRoutes.listModules(composerId: id)
      AF.request(restRequest).validate().responseData { response in
        if case let .success(jsonData) = response.result,
           let modules = try? JSONDecoder().decode([ModuleResult].self, from: jsonData) {
          self.latestModuleResponse = Search.Response<ModuleResult>(result: modules, text: "")
          self.presenter?.presentSearchResponse(self.latestModuleResponse)
        }
      }
    } else if type == .group {
      let restRequest = RESTRoutes.listComposers(groupId: id)
      AF.request(restRequest).validate().responseData { response in
        if case let .success(jsonData) = response.result,
           let composers = try? JSONDecoder().decode([ComposerResult].self, from: jsonData) {
          self.presenter?.presentSearchResponse(Search.Response<ComposerResult>(result: composers, text: ""))
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
    fetcher = ModuleFetcher(delegate: self)

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

  func addToPlaylist(moduleId _: Int, playlistId _: String) {}

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
  func fetcherStateChanged(_: ModuleFetcher, state: FetcherState) {
    log.debug(state)
    switch state {
    case var .done(mmd):
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
    case let .downloading(progress):
      log.debug(progress)
      presenter?.presentDownloadProgress(response: Search.ProgressResponse(progress: progress))
    case let .failed(err):
      log.error(err.debugDescription)
      if downloadQueue.count == 0 {
        presenter?.presentDownloadProgress(response: Search.ProgressResponse(progress: 0, error: err))
      }
      fetchNextQueuedModule()
    default:
      log.verbose("noop")
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
