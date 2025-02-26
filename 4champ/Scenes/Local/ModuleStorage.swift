//
//  ModuleStorage.swift
//  ampplayer
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import CoreData

enum StorageError: Error {
  case migrationFailed
}

protocol ModuleStorageInterface {
  var currentPlaylist: Playlist? { get set }
  var coordinatorError: StorageError? { get }

  func createFRC<T: NSManagedObject>(fetchRequest: NSFetchRequest<T>, entityName: String) -> NSFetchedResultsController<T>
  func addStorageObserver(_ observer: ModuleStorageObserver)
  func removeStorageObserver(_ observer: ModuleStorageObserver)
  func addModule(module: MMD)
  func toggleFavorite(module: MMD) -> MMD?
  func getModuleById(_ id: Int) -> MMD?
  func getRandomModule() -> MMD?
  func deleteModule(module: MMD)
  func resetCoordinatorError()
  func rebuildDatabaseFromDisk()
  func createPlaylist(name: String, id: String?) -> Playlist
  func saveContext()
  func fetchModuleInfo(_ id: Int) -> ModuleInfo?
  func fetchModuleInfoByKey(_ key: String) -> ModuleInfo?

  /// Get unique id for a module
  /// - parameter service: Identifies the service for which to get the id for. Valid services are all non-amp ones.
  func getNextModuleId(service: ModuleService) -> Int
}

protocol ModuleStorageObserver: class {
  func metadataChange(_ mmd: MMD)
  func playlistChange()
}

class ModuleStorage: NSObject {
  private var observers: [ModuleStorageObserver] = []
  private var _currentPlaylist: Playlist?
  private var _storageError: StorageError?

  /// Identifier ranges for different services
  private let idRanges = [
    ModuleService.amp: 0..<1000000,
    ModuleService.local: 1000000..<2000000
  ]

    // MARK: Core Data lazy initialisers
  private lazy var managedObjectModel: NSManagedObjectModel = {
    let modelURL = Bundle.main.url(forResource: "AmpCDModel", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
  }()

  private lazy var applicationDocumentsDirectory: URL = {
    // The directory the application uses to store the Core Data store file.
    // This code uses a directory named in the application's documents Application Support directory.
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[urls.count-1]
  }()

  lazy var managedObjectContext: NSManagedObjectContext = {
    var moc: NSManagedObjectContext?
//    if #available(iOS 10.0, *) {
//      moc = self.persistentContainer.viewContext
//    } else {
      let coordinator = self.persistentStoreCoordinator
      moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//      moc?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
      moc?.persistentStoreCoordinator = coordinator
//    }
    return moc!
  }()

  @available(iOS 10.0, *)
  private lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "AmpCDModel")
    container.loadPersistentStores(completionHandler: { (_, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()

  private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.appendingPathComponent("bbbb.sqlite")
    var failureReason = "There was an error creating or loading the application's saved data."
    do {
      // Configure automatic migration.
      let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true ]
      try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
    } catch {
      // Report any error we got.
      var dict = [String: AnyObject]()
      dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
      dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
      dict[NSUnderlyingErrorKey] = error as NSError
      log.error("Unresolved error \(dict)")

      // Instead of aborting, delete the SQLite file and try again
      try? FileManager.default.removeItem(at: url)
      do {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url)
        _storageError = .migrationFailed
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
    return coordinator
  }()

  override init() {
    super.init()
    var _ = persistentStoreCoordinator
    let name = managedObjectContext.name
    log.info(name ?? "managedObjectContext does not have name")

    setCurrentPlaylist(playlist: getDefaultPlaylist())
  }

  private func getDefaultPlaylist() -> Playlist {
    let fetchRequest = NSFetchRequest<Playlist>.init(entityName: "Playlist")
    fetchRequest.sortDescriptors = []
    let filterString = "plId == 'default'"
    fetchRequest.predicate = NSPredicate.init(format: filterString)
    let frc = createFRC(fetchRequest: fetchRequest, entityName: "Playlist")
    try? frc.performFetch()
    guard let defaultPl = frc.fetchedObjects?.first else {
      // No Default playlist yet, must create it
      return createPlaylist(name: "default", id: "default")
    }
    return defaultPl
  }

  private func setCurrentPlaylist(playlist: Playlist?) {
    _currentPlaylist = playlist
    _ = observers.map { $0.playlistChange() }
  }

}

extension ModuleStorage: ModuleStorageInterface {
  var currentPlaylist: Playlist? {
    get {
      return _currentPlaylist
    }
    set {
      setCurrentPlaylist(playlist: newValue)
    }
  }

  var coordinatorError: StorageError? {
    _storageError
  }

  func resetCoordinatorError() {
    _storageError = nil
  }

  func createFRC<T>(fetchRequest: NSFetchRequest<T>, entityName: String) -> NSFetchedResultsController<T> where T: NSManagedObject {

    // Initialize Fetch Request
    let fetchedResultsController = NSFetchedResultsController<T>(fetchRequest: fetchRequest,
                                                                 managedObjectContext: managedObjectContext,
                                                                 sectionNameKeyPath: nil, cacheName: nil)

    return fetchedResultsController
  }

  func addStorageObserver(_ observer: ModuleStorageObserver) {
    observers.append(observer)
  }

  func removeStorageObserver(_ observer: ModuleStorageObserver) {
    if let index = observers.firstIndex(where: { mso -> Bool in
      return mso === observer
    }) {
      observers.remove(at: index)
    }
  }

  func addModule(module: MMD) {
    log.debug("")
    guard getModuleById(module.id!) == nil else {
      return // already saved
    }

    let cdModule = ModuleInfo.init(entity: NSEntityDescription.entity(forEntityName: "ModuleInfo", in: managedObjectContext)!, insertInto: managedObjectContext)
    cdModule.modAuthor = module.composer
    cdModule.modName = module.name
    cdModule.modId = NSNumber.init(value: module.id!)
    cdModule.modURL = module.downloadPath?.absoluteString
    cdModule.modSize = NSNumber.init(value: module.size!)
    cdModule.modType = module.type
    cdModule.modLocalPath = module.localPath?.lastPathComponent
    cdModule.added = NSDate.init(timeIntervalSinceNow: 0)
    cdModule.lastPlayed = NSDate.init(timeIntervalSinceNow: 0)
    cdModule.modFavorite = NSNumber.init(value: module.favorite)
    cdModule.playCount = 1
    cdModule.modDLStatus = 0
    cdModule.preview = 0
    cdModule.radioOnly = 0
    cdModule.shared = nil
    cdModule.serviceId = NSNumber.init(value: module.serviceId?.rawValue ?? 1)
    cdModule.serviceKey = module.serviceKey
    cdModule.loop = 0
    saveContext()

    let mmd = MMD.init(cdi: cdModule)
    _ = observers.map {
      $0.metadataChange(mmd)
    }
  }

  func deleteModule(module: MMD) {
    if let moduleInfo = fetchModuleInfo(module.id!) {
      if let localPath = moduleInfo.modLocalPath {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(localPath)
        log.info("Deleting module \(url.lastPathComponent)")
        do {
          try FileManager.default.removeItem(at: url)
        } catch {
          log.error("\(error)")
        }
      }
      managedObjectContext.delete(moduleInfo)
      saveContext()
      _ = observers.map {
        $0.metadataChange(module)
      }
    }
  }

  func getRandomModule() -> MMD? {
    guard let allModules = try? managedObjectContext.fetch(NSFetchRequest.init(entityName: "ModuleInfo")),
    allModules.count > 0 else {
      return nil
    }
    let index = Int.random(in: 0 ..< allModules.count)
    if let cdi = allModules[index] as? ModuleInfo {
      return MMD.init(cdi: cdi)
    }
    return nil
  }

  func getModuleById(_ id: Int) -> MMD? {
    if let moduleInfo = fetchModuleInfo(id) {
      return MMD.init(cdi: moduleInfo)
    }
    return nil
  }

  func toggleFavorite(module: MMD) -> MMD? {
    addModule(module: module)
    if let cdModule = fetchModuleInfo(module.id!),
      let favorite = cdModule.modFavorite?.boolValue {
      if favorite {
        cdModule.modFavorite = 0
      } else {
        cdModule.modFavorite = 1
        ReviewActions.increment()
      }
      saveContext()
      let mmd = MMD.init(cdi: cdModule)
      _ = observers.map {
        $0.metadataChange(mmd)
      }
      return mmd
    }
    return nil
  }

  func toggleLoop(module: MMD) -> MMD? {
    addModule(module: module)
    if let cdModule = fetchModuleInfo(module.id!), let loop = cdModule.loop {
      let toggled: Bool = loop.intValue > 0 ? false : true
      cdModule.loop = NSNumber(value: toggled)
      saveContext()
      let mmd = MMD.init(cdi: cdModule)
      _ = observers.map {
        $0.metadataChange(mmd)
      }
      return mmd
    }
    return nil
  }

  func createPlaylist(name: String, id: String?) -> Playlist {
    let cdPlaylist = Playlist.init(entity: NSEntityDescription.entity(forEntityName: "Playlist", in: managedObjectContext)!, insertInto: managedObjectContext)

    let plId = id ?? UUID().uuidString
    cdPlaylist.plId = plId
    cdPlaylist.plName = name
    cdPlaylist.locked = false

    saveContext()

    return cdPlaylist
  }

  func saveContext() {
    do {
      try managedObjectContext.save()
    } catch {
      log.error(error)
    }
  }

  func fetchModuleInfo(_ id: Int) -> ModuleInfo? {
    let fetchRequest = NSFetchRequest<ModuleInfo>.init(entityName: "ModuleInfo")
    let predicate = NSPredicate.init(format: "modId == \(id)")
    fetchRequest.predicate = predicate
    return fetchModuleInfo(fetchRequest)
  }

  func fetchModuleInfoByKey(_ key: String) -> ModuleInfo? {
    let fetchRequest = NSFetchRequest<ModuleInfo>.init(entityName: "ModuleInfo")
    let predicate = NSPredicate.init(format: "serviceKey == %@", key)
    fetchRequest.predicate = predicate
    return fetchModuleInfo(fetchRequest)
  }

  func getNextModuleId(service: ModuleService) -> Int {
    guard let range = idRanges[service] else {
      fatalError("Invalid service or no range found")
    }
    let request = NSFetchRequest<ModuleInfo>.init(entityName: "ModuleInfo")
    let lowerBound = NSPredicate.init(format: "modId >= \(range.lowerBound) AND modId < \(range.upperBound)")
    request.predicate = lowerBound
    request.fetchLimit = 1
    let sortDescriptor = NSSortDescriptor(key: "modId", ascending: false)
    request.sortDescriptors = [sortDescriptor]

    if let modInfo = fetchModuleInfo(request), let modId = modInfo.modId?.intValue {
      return modId + 1
    }
    // no IDs yet for this service range
    return range.lowerBound
  }

  func rebuildDatabaseFromDisk() {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil) else { return }

    for fileURL in fileURLs {
      guard !fileURL.lastPathComponent.contains("bbbb.sqlite") else { continue }
      guard let suffix = fileURL.lastPathComponent.split(separator: ".").last else { continue }
      guard MMD.supportedTypes.contains(String(suffix).uppercased()) else { continue }
      let mmd = MMD.init(fileURL: fileURL)
      addModule(module: mmd)
    }

    resetCoordinatorError()
  }

  private func fetchModuleInfo(_ request: NSFetchRequest<ModuleInfo>) -> ModuleInfo? {
    do {
      let match = try managedObjectContext.fetch(request)
      if let module = match.first {
        return module
      }
    } catch {
      log.error(error)
    }
    return nil
  }
}

extension MMD {
  init(fileURL: URL) {
    self.init()
    let filename = fileURL.lastPathComponent
    let nameComponents = filename.components(separatedBy: ".")
    localPath = fileURL
    name = nameComponents.dropLast().joined(separator: ".")
    serviceId = .local
    serviceKey = fileURL.lastPathComponent
    id = moduleStorage.getNextModuleId(service: .local)
    type = filename.split(separator: ".").last?.uppercased()
    composer = nil
    if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
      size = ((attrs[FileAttributeKey.size] as? Int) ?? 0) / 1024
    }
  }
}
