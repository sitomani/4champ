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
  func doSomething(request: Local.Something.Request)
  func playModule(at: IndexPath)
  func sortAndFilter(request: Local.SortFilter.Request)
  // Direct getters
  func moduleCount() -> Int
  func getModule(at: IndexPath) -> MMD
}

protocol LocalDataStore
{
  var localFRC: NSFetchedResultsController<ModuleInfo> { get }
  //var name: String { get set }
}

class LocalInteractor: LocalBusinessLogic, LocalDataStore
{
  var presenter: LocalPresentationLogic?
  var worker: LocalWorker?
  //var name: String = ""
  
  private var moduleStorage: ModuleStorage = ModuleStorage()

  lazy var localFRC: NSFetchedResultsController<ModuleInfo> = {
    // Initialize Fetch Request
    let fetchRequest = NSFetchRequest<ModuleInfo>(entityName: "ModuleInfo")
    fetchRequest.fetchBatchSize = 20
    
    // Add Sort Descriptors
    let sortDescriptor = NSSortDescriptor(key: "modName", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    //      NSString* flt = [NSString stringWithFormat:@"(radioOnly == NO OR radioOnly == NULL)"];
    fetchRequest.predicate = NSPredicate.init(format: "(radioOnly == NO OR radioOnly == NULL)")
    // Initialize Fetched Results Controller
    let fetchedResultsController = NSFetchedResultsController<ModuleInfo>(fetchRequest: fetchRequest, managedObjectContext: moduleStorage.managedObjectContext , sectionNameKeyPath: nil, cacheName: nil)
    
    return fetchedResultsController
  }()
  
  // MARK: Do something
  func doSomething(request: Local.Something.Request)
  {
    worker = LocalWorker()
    worker?.doSomeWork()
    do {
      try localFRC.performFetch()
    } catch {
      log.error(error)
    }
    let response = Local.Something.Response()
    presenter?.presentSomething(response: response)
  }
  
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
    let sortDescriptor = NSSortDescriptor(key: sortkey, ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
    localFRC.fetchRequest.sortDescriptors = [sortDescriptor]

    var filterString = "(radioOnly == NO OR radioOnly == NULL)"
    if let filterText = request.filterText, filterText.count > 0 {
      filterString += " AND (modName like[cd] '*\(filterText)*' OR modAuthor like[cd] '*\(filterText)*')"
    }
    localFRC.fetchRequest.predicate = NSPredicate.init(format: filterString)
    try! localFRC.performFetch()
    presenter?.presentSomething(response: Local.Something.Response())
  }
  
  func moduleCount() -> Int {
    return localFRC.fetchedObjects?.count ?? 0
  }
  
  func getModule(at: IndexPath) -> MMD {
    if let mi = localFRC.fetchedObjects?[at.row] {
      var module = MMD()
      module.type = mi.modType ?? ""
      module.id = mi.modId?.intValue ?? 0
      module.localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(mi.modLocalPath!)
      module.name = mi.modName ?? ""
      module.size = mi.modSize?.intValue ?? 0
      module.composer = mi.modAuthor ?? ""
      return module
    }
    return MMD()
  }
  
  func playModule(at: IndexPath) {
    let mmd = getModule(at: at)
    modulePlayer.play(mmd: mmd)
  }
}
