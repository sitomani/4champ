//
//  SearchInteractor.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniem. All rights reserved.
//

import UIKit
import Alamofire
import Foundation

typealias ModuleResult = [SearchResultModule]

struct SearchResultModule: Codable {
  let name, composer: LabelHref
  let format: String
  let size, downloadCount: String
  let infos: String
}

struct LabelHref: Codable {
  let label: String
  let href: String
}

typealias ComposerResult = [SearchResultComposer]

struct SearchResultComposer: Codable {
  let handle: LabelHref
  let realname, groups: String
}

typealias GroupResult = [LabelHref]

//   let transaction = try? newJSONDecoder().decode(Transaction.self, from: jsonData)

import Foundation


protocol SearchBusinessLogic
{
  func search(keyword: String, type: SearchType)
  func download(moduleId: Int)
}

protocol SearchDataStore
{
  var moduleResult: [SearchResultModule] { get set }
}

class SearchInteractor: SearchBusinessLogic, SearchDataStore
{
  var presenter: SearchPresentationLogic?
  var worker: SearchWorker?

  var moduleResult: [SearchResultModule] = []
  
  private var currentRequest: Alamofire.DataRequest?
  
  func search(keyword: String, type: SearchType) {
    log.debug("keyword: \(keyword), type: \(type.rawValue)")
    if currentRequest != nil {
      currentRequest?.cancel()
      currentRequest = nil
    }
    let restRequest = RESTRoutes.search(type: type, text: keyword, position: 0)
    currentRequest = Alamofire.request(restRequest).validate().responseJSON { (json) in
      log.debug("\(json.result) \(keyword)")
      if json.result.isSuccess {
        if let modules = try? JSONDecoder().decode(ModuleResult.self, from: json.data!) {
          self.moduleResult = modules
          self.presenter?.presentModules(response: Search.ModuleResponse(result: modules))
        } else if let composers = try? JSONDecoder().decode(ComposerResult.self, from: json.data!) {
          self.presenter?.presentComposers(response: Search.ComposerResponse(result: composers))
        } else if let groups = try? JSONDecoder().decode(GroupResult.self, from: json.data!) {
          self.presenter?.presentGroups(response: Search.GroupResponse(result: groups))
        } else {
          self.moduleResult = []
          self.presenter?.presentModules(response: Search.ModuleResponse(result: []))
        }
      }
      self.currentRequest = nil
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
      modulePlayer.play(mmd: mmd)
    case .downloading(let progress):
      log.debug(progress)
    default:
      log.debug("foo")
    }
  }
}
