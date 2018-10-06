//
//  SearchInteractor.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniem. All rights reserved.
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
          self.presenter?.presentModules(response: Search.ModuleResponse(result: modules))
        } else if let composers = try? JSONDecoder().decode(ComposerResult.self, from: json.data!) {
          self.presenter?.presentComposers(response: Search.ComposerResponse(result: composers))
        } else if let groups = try? JSONDecoder().decode(GroupResult.self, from: json.data!) {
          self.presenter?.presentGroups(response: Search.GroupResponse(result: groups))
        } else {
          self.presenter?.presentModules(response: Search.ModuleResponse(result: []))
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
            self.presenter?.presentModules(response: Search.ModuleResponse(result: modules))
          }
        }
      }
    } else if type == .group {
      let restRequest = RESTRoutes.listComposers(groupId: id)
      Alamofire.request(restRequest).validate().responseJSON { json in
        if json.result.isSuccess {
          if let composers = try? JSONDecoder().decode(ComposerResult.self, from: json.data!) {
            self.presenter?.presentComposers(response: Search.ComposerResponse(result: composers))
          }
        }
      }
    } else {
      log.error("Invalid type for auto fetch \(type)")
    }
  }
  
  func download(moduleId: Int) {
    let fetcher = ModuleFetcher.init(delegate: self)
    fetcher.fetchModule(ampId: moduleId)
  }
}

extension SearchInteractor: ModuleFetcherDelegate {
  func fetcherStateChanged(_ fetcher: ModuleFetcher, state: FetcherState) {
    log.debug(state)
    switch state {
    case .done(let mmd):
      presenter?.presentDownloadProgress(response: Search.ProgressResponse(progress: 1.0))
      modulePlayer.play(mmd: mmd)
      removeBufferHead()
    case .downloading(let progress):
      log.debug(progress)
      presenter?.presentDownloadProgress(response: Search.ProgressResponse(progress: progress))
    default:
      log.verbose("noop")
    }
  }
  
  /// Keeps the playlist short so that the disk is not flooded with modules
  private func removeBufferHead() {
    guard modulePlayer.playlist.count > Constants.radioBufferLen else { return }
    let current = modulePlayer.playlist.removeFirst()
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
