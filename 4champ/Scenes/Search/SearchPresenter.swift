//
//  SearchPresenter.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SearchPresentationLogic
{
  func presentSearchResponse<T>(_ response: Search.Response<T>)
  func presentDownloadProgress(response: Search.ProgressResponse)
  func presentBatchProgress(response: Search.BatchDownload.Response)
  func presentMetadataChange(response: Search.MetaDataChange.Response)
  func presentDeletion(response: Search.MetaDataChange.Response)
}

/// Search result presentation class. Presenter wraps the json originating
/// objects into presentable structs for `SearchViewController`
class SearchPresenter: SearchPresentationLogic
{
  weak var viewController: SearchDisplayLogic?
  
  private let nameSorterBlock: (NameComparable, NameComparable) -> Bool = { (a, b) in
    return a.name.compare(b.name, options: .caseInsensitive) == .orderedAscending
  }
  
  func presentSearchResponse<T>(_ response: Search.Response<T>) {
    var modules: [MMD] = []
    var composers: [ComposerInfo] = []
    var groups: [GroupInfo] = []
    switch T.self {
    case is ComposerResult.Type:
      composers = (response as! Search.Response<ComposerResult>).result.compactMap {
        return getComposerInfoFrom(resultObject: $0)
      }.sorted(by: nameSorterBlock)
      break;
    case is ModuleResult.Type:
      modules = (response as! Search.Response<ModuleResult>).result.map {
        return getMMDFrom(resultObject: $0)
      }.sorted(by: nameSorterBlock)
      break;
    case is GroupResult.Type:
      groups = (response as! Search.Response<GroupResult>).result.compactMap {
        return getGroupInfoFrom(resultObject: $0)
      }.sorted(by: nameSorterBlock)
      break;
    default:
        break;
    }
    viewController?.displayResult(viewModel: Search.ViewModel(modules: modules,
                                                              composers: composers,
                                                              groups: groups,
                                                              text: response.text))

  }
      
  func presentDownloadProgress(response: Search.ProgressResponse) {
    var vm = Search.ProgressResponse.ViewModel(progress: response.progress)
    if let _ = response.error {
      vm.error = "Error_ComposerDisabled".l13n()
    }
    DispatchQueue.main.async {
      self.viewController?.displayDownloadProgress(viewModel: vm)
    }
  }
  
  func presentBatchProgress(response: Search.BatchDownload.Response) {
    log.debug("")
    let processedCount = response.originalQueueLength - response.queueLength + (response.queueLength > 0 ? 1 : 0)
    let vm = Search.BatchDownload.ViewModel(batchSize: response.originalQueueLength,
                                            processed:processedCount,
                                            complete: response.complete,
                                            favoritedModuleId: response.favoritedModuleId)
    DispatchQueue.main.async {
      self.viewController?.displayBatchProgress(viewModel: vm)
    }
  }
  
  func presentMetadataChange(response: Search.MetaDataChange.Response) {
    let vm = Search.MetaDataChange.ViewModel(module: response.module)
    DispatchQueue.main.async {
      self.viewController?.displayMetaDataChange(viewModel: vm)
    }
  }
  
  func presentDeletion(response: Search.MetaDataChange.Response) {
    let vm = Search.MetaDataChange.ViewModel(module: response.module)
    DispatchQueue.main.async {
      self.viewController?.displayDeletion(viewModel: vm)
    }
  }
  
  private func getIdFrom(href: String) -> Int? {
    guard let cUri = URL.init(string: href) else { return nil }
    guard let idString  = cUri.query?.split(separator: "=").last else { return nil }
    return Int(idString)
  }
  
  private func getGroupInfoFrom(resultObject: GroupResult) -> GroupInfo? {
    guard let id = getIdFrom(href: resultObject.href) else { return nil }
    return GroupInfo(id: id,
                     name: resultObject.label)

  }
  
  private func getComposerInfoFrom(resultObject: ComposerResult) -> ComposerInfo? {
    guard let id = getIdFrom(href: resultObject.handle.href) else { return nil }
    return ComposerInfo(id: id,
                        name: resultObject.handle.label,
                        realName: resultObject.realname,
                        groups: resultObject.groups)
  }
  
  private func getMMDFrom(resultObject: ModuleResult) -> MMD {
    let id: Int = getIdFrom(href: resultObject.name.href) ?? 0
    var mmd = MMD()
    mmd.id = id
    mmd.downloadPath = URL.init(string: resultObject.name.href)
    mmd.name = resultObject.name.label
    mmd.size = Int(resultObject.size.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
    mmd.type = resultObject.format
    mmd.composer = resultObject.composer.label
    mmd.serviceId = .amp
    mmd.note = resultObject.note
    if let localCopy = moduleStorage.getModuleById(id) {
      mmd.localPath = localCopy.localPath
    }
    return mmd
  }

}
