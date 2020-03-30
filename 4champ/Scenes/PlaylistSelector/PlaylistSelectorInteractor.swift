//
//  PlaylistSelectorInteractor.swift
//  4champ
//
//  Created by Aleksi Sitomaniemi on 13.3.2020.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import CoreData

protocol PlaylistSelectorBusinessLogic
{
  func prepare(request: PlaylistSelector.PrepareSelection.Request)
  func appendToPlaylist(request: PlaylistSelector.Append.Request)
}

protocol PlaylistSelectorDataStore
{
}

class PlaylistSelectorInteractor: PlaylistSelectorBusinessLogic, PlaylistSelectorDataStore
{
  var presenter: PlaylistSelectorPresentationLogic?
  var frc: NSFetchedResultsController<Playlist>?
  
  private var playlists:[PLMD] = []
  private var module: MMD?
  private var selectedPlaylist: Playlist?
  
  func prepare(request: PlaylistSelector.PrepareSelection.Request)
  {
    self.module = request.module
    let fetchRequest = NSFetchRequest<Playlist>.init(entityName: "Playlist")
    fetchRequest.sortDescriptors = []
    
    let filterString = "plId != 'radioList'"
    fetchRequest.predicate = NSPredicate.init(format: filterString)
    frc = moduleStorage.createFRC(fetchRequest: fetchRequest, entityName: "Playlist")
    try! frc?.performFetch()
    
    if let plObjects = frc?.fetchedObjects {
      var plMetaData = plObjects.map {
        PLMD(id: $0.plId, name: $0.plName, current: false, modules: [] )
      }
      
      for pl in plObjects {
        for mi in pl.modules ?? [] {
          let modId = (mi as! ModuleInfo).modId?.intValue ?? 0
          if let index = plMetaData.firstIndex (where: { $0.id == pl.plId }) {
            plMetaData[index].modules.append(modId)
          }
        }
      }
      
      plMetaData.sort { (pla, plb) -> Bool in
        if pla.id == "default" {
          return true
        }
        if plb.id == "default" {
          return false
        }
        return pla.name! < plb.name!
      }
      
      playlists = plMetaData
      
      let response = PlaylistSelector.PrepareSelection.Response(module: request.module, playlistOptions: plMetaData)
      presenter?.presentSelector(response: response)
    }
  }
  func appendToPlaylist(request: PlaylistSelector.Append.Request) {
    guard let modId = module?.id else {
      return
    }
    
    let target = playlists[request.playlistIndex].id ?? "default"
    let pl = getPlaylist(with: target)
    let completed = PlaylistSelector.Append.Response(status: DownloadStatus.complete)
    
    selectedPlaylist = pl
    // Three scenarios:
    if let modInfo = moduleStorage.fetchModuleInfo(modId) {
      // 1. Module is already in the database, just append to the selected playlist
      pl?.addToModules(modInfo)
      moduleStorage.saveContext()
      presenter?.presentAppend(response: completed)
    } else {
      if let _ = module?.localPath {
        // 2. Module is downloaded (radio/search) but not yet in database
        moduleStorage.addModule(module: module!)
        if let modInfo = moduleStorage.fetchModuleInfo(modId) {
          pl?.addToModules(modInfo)
          moduleStorage.saveContext()
          presenter?.presentAppend(response: completed)
        }
      } else {
        // 3. Module is not yet downloaded
        let fetcher = ModuleFetcher(delegate: self)
        fetcher.fetchModule(ampId: module!.id!)
      }
    }
  }
  
  private func getPlaylist(with id: String) -> Playlist? {
    let fetchRequest = NSFetchRequest<Playlist>.init(entityName: "Playlist")
    fetchRequest.sortDescriptors = []
    let filterString = "plId == '\(id)'"
    fetchRequest.predicate = NSPredicate.init(format: filterString)
    let tmp = moduleStorage.createFRC(fetchRequest: fetchRequest, entityName: "Playlist")
    try! tmp.performFetch()
    return tmp.fetchedObjects?.first
  }
}

extension PlaylistSelectorInteractor: ModuleFetcherDelegate {
  func fetcherStateChanged(_ fetcher: ModuleFetcher, state: FetcherState) {
    log.debug(state)
    switch state {
    case .done(let mmd):
      moduleStorage.addModule(module: mmd)
      if let added = moduleStorage.fetchModuleInfo(mmd.id!) {
        selectedPlaylist?.addToModules(added)
        moduleStorage.saveContext()
        let resp = PlaylistSelector.Append.Response(status: DownloadStatus.complete)
        presenter?.presentAppend(response: resp)
      }
    case .downloading(let progress):
      log.debug(progress)
      let resp = PlaylistSelector.Append.Response(status: DownloadStatus.downloading(progress: Int(progress*100)))
      presenter?.presentAppend(response: resp)
    case .failed(let err):
      log.error(err.debugDescription)
      let resp = PlaylistSelector.Append.Response(status: DownloadStatus.failed(error: err!))
      presenter?.presentAppend(response: resp)
    default:
      log.verbose("noop")
    }
  }
}
