//
//  LocalInteractor.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//


import UIKit
import CoreData

protocol LocalBusinessLogic
{
  func playModule(at: IndexPath)
  func sortAndFilter(request: Local.SortFilter.Request)
  func deleteModule(at: IndexPath)
  func toggleFavorite(at: IndexPath)
  // Direct getters
  func moduleCount() -> Int
  func getModule(at: IndexPath) -> MMD
}

protocol LocalDataStore
{
  var frc: NSFetchedResultsController<ModuleInfo>? { get }
}

class LocalInteractor: NSObject, LocalBusinessLogic, LocalDataStore
{
  var presenter: LocalPresentationLogic?
  var frc: NSFetchedResultsController<ModuleInfo>?
  
  // MARK: API
  func sortAndFilter(request: Local.SortFilter.Request) {
    var sortkey = "modName"
    switch request.sortKey {
    case .type: sortkey = "modType"
    case .module: sortkey = "modName"
    case .composer: sortkey = "modAuthor"
    case .size: sortkey = "modSize"
    case .favorite: sortkey = "modFavorite"
    default:
      log.debug("Behaviour sorts not supported yet")
      sortkey = "modName"
    }
    // Add Sort Descriptors
    let sortDescriptor: NSSortDescriptor
    if request.sortKey == .favorite {
      sortDescriptor = NSSortDescriptor(key: sortkey, ascending: false)
    } else {
      sortDescriptor = NSSortDescriptor(key: sortkey, ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
    }
    
    let fetchRequest = NSFetchRequest<ModuleInfo>.init(entityName: "ModuleInfo")
    fetchRequest.sortDescriptors = [sortDescriptor]

    var filterString = "(radioOnly == NO OR radioOnly == NULL)"
    if let filterText = request.filterText, filterText.count > 0 {
      filterString += " AND (modName like[cd] '*\(filterText)*' OR modAuthor like[cd] '*\(filterText)*')"
    }
    fetchRequest.predicate = NSPredicate.init(format: filterString)
    frc = moduleStorage.createFRC(fetchRequest: fetchRequest, entityName: "ModuleInfo")
    frc?.delegate = self
    try! frc?.performFetch()
    presenter?.presentModules(response: Local.SortFilter.Response())
  }
  
  func moduleCount() -> Int {
    return frc?.fetchedObjects?.count ?? 0
  }
  
  func getModule(at: IndexPath) -> MMD {
    if let mi = frc?.fetchedObjects?[at.row] {
      var module = MMD()
      module.type = mi.modType ?? ""
      module.id = mi.modId?.intValue ?? 0
      module.localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(mi.modLocalPath!)
      module.name = mi.modName ?? ""
      module.size = mi.modSize?.intValue ?? 0
      module.composer = mi.modAuthor ?? ""
      module.favorite = mi.modFavorite?.boolValue ?? false
      return module
    }
    return MMD()
  }
  
  func playModule(at: IndexPath) {
    let mmd = getModule(at: at)
    
    if mmd.fileExists() {
        modulePlayer.play(mmd: mmd)
    } else {
      presenter?.presentPlayerError(.fileNotFound(mmd: mmd))
      moduleStorage.deleteModule(module: mmd)
    }
  }
  
  func deleteModule(at: IndexPath) {
    let mmd = getModule(at: at)
    if mmd.fileExists() {
      moduleStorage.deleteModule(module: mmd)
    }
  }
  
  func toggleFavorite(at: IndexPath) {
    let mmd = getModule(at: at)
    if mmd.fileExists() {
      _ = moduleStorage.toggleFavorite(module: mmd)
    }
  }
}

extension LocalInteractor: NSFetchedResultsControllerDelegate {
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//    presenter?.presentModules(response: Local.SortFilter.Response())
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

    switch type {
    case .insert:
      presenter?.presentInsert(newIndexPath!)
    case .delete:
      presenter?.presentDeletion(indexPath!)
    case .update:
      presenter?.presentUpdate(indexPath!)
    default:
      presenter?.presentModules(response: Local.SortFilter.Response())
    }
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//    presenter?.presentModules(response: Local.SortFilter.Response())
  }
}