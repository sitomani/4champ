//
//  SearchInteractor.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import Alamofire
import Foundation

/// Search Interactor business logic interface
protocol SearchBusinessLogic
{
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
}

/// Search Interactor datastore
protocol SearchDataStore
{
  var autoListTitle: String? { get set }
  var autoListId: Int? { get set }
  var autoListType: SearchType? { get set }
  var pagingIndex: Int { get }
}

/// Implementation of Search business logic
class SearchInteractor: SearchBusinessLogic, SearchDataStore
{
  var presenter: SearchPresentationLogic?

  var autoListTitle: String?
  var autoListId: Int?
  var autoListType: SearchType?
  var pagingIndex: Int = 0
  
  private var currentRequest: Alamofire.DataRequest?
  private var downloadQueue: [Int] = []
  private var originalQueueLenght: Int = 0
  private var fetcher: ModuleFetcher?
  private var latestModuleResponse: Search.ModuleResponse = Search.ModuleResponse(result: [], text: "")
  
  func search(_ request: Search.Request) {
    log.debug("keyword: \(request.text), type: \(request.type), pagingIndex: \(request.pagingIndex)")
    if currentRequest != nil {
      currentRequest?.cancel()
      currentRequest = nil
    }
    let restRequest = RESTRoutes.search(type: request.type, text: request.text, position: request.pagingIndex)
    currentRequest = Alamofire.request(restRequest).validate().responseJSON { (json) in
      if let checkReq = self.currentRequest?.request, checkReq != json.request {
        log.warning("overlapping requests. Bypass all except most recent.")
        return
      }
      if json.result.isSuccess {
        log.info("\(json.result) \(request.text)")
        self.pagingIndex = request.pagingIndex
        if let modules = try? JSONDecoder().decode(ModuleResult.self, from: json.data!) {
          self.latestModuleResponse = Search.ModuleResponse(result: modules, text: request.text)
          self.presenter?.presentModules(response: self.latestModuleResponse)
        } else if let composers = try? JSONDecoder().decode(ComposerResult.self, from: json.data!) {
          self.presenter?.presentComposers(response: Search.ComposerResponse(result: composers, text: request.text))
        } else if let groups = try? JSONDecoder().decode(GroupResult.self, from: json.data!) {
          self.presenter?.presentGroups(response: Search.GroupResponse(result: groups, text: request.text))
        } else {
          self.latestModuleResponse = Search.ModuleResponse(result: [], text: request.text)
          self.presenter?.presentModules(response: self.latestModuleResponse)
        }
      } else {
        log.error(String.init(describing: json.error))
      }
      self.currentRequest = nil
    }
  }
  
  func triggerAutoFetchList() {
    guard let id = autoListId, let type = autoListType else { return }
    
    if type == .composer {
      let restRequest = RESTRoutes.listModules(composerId: id)
      Alamofire.request(restRequest).validate().responseJSON { (json) in
        if json.result.isSuccess {
          if let modules = try? JSONDecoder().decode(ModuleResult.self, from: json.data!) {
            self.latestModuleResponse = Search.ModuleResponse(result: modules, text: "")
            self.presenter?.presentModules(response: self.latestModuleResponse)
          }
        }
      }
    } else if type == .group {
      let restRequest = RESTRoutes.listComposers(groupId: id)
      Alamofire.request(restRequest).validate().responseJSON { json in
        if json.result.isSuccess {
          if let composers = try? JSONDecoder().decode(ComposerResult.self, from: json.data!) {
            self.presenter?.presentComposers(response: Search.ComposerResponse(result: composers, text:""))
          }
        }
      }
    } else {
      log.error("Invalid type for auto fetch \(type)")
    }
  }
  
  func download(moduleId: Int) {
    //reset the download queue if single downloads are triggered
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
  
  private func doDownload(moduleId: Int) {
    // Always create a new fetcher. Fetchers will be released
    // Once the fetch is complete
    fetcher = ModuleFetcher.init(delegate: self)
    fetcher?.fetchModule(ampId: moduleId)
  }
    
  func downloadModules(_ request: Search.BatchDownload.Request) {
    downloadQueue = request.moduleIds
    originalQueueLenght = request.moduleIds.count
    fetchNextQueuedModule()
  }
  
  func cancelDownload() {
    downloadQueue = []
    fetcher?.cancel()
  }
  
  func addToPlaylist(moduleId: Int, playlistId: String) {
    
  }
  
  private func fetchNextQueuedModule() {
    var resp = Search.BatchDownload.Response(originalQueueLength: originalQueueLenght, queueLength: downloadQueue.count, complete: false)
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
    case .done(let mmd):
      presenter?.presentDownloadProgress(response: Search.ProgressResponse(progress: 1.0))
      if originalQueueLenght == 0 {
        modulePlayer.play(mmd: mmd)
        removeBufferHead()
      } else {
        moduleStorage.addModule(module: mmd)
        fetchNextQueuedModule()
      }
    case .downloading(let progress):
      log.debug(progress)
      presenter?.presentDownloadProgress(response: Search.ProgressResponse(progress: progress))
    case .failed(let err):
      log.error(err.debugDescription)
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
