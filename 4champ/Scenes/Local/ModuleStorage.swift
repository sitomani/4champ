//
//  ModuleStorage.swift
//  ampplayer
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//


import Foundation
import CoreData

protocol ModuleStorageInterface {
  func addModule(module: MMD)
}


class ModuleStorage {
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
      moc?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
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
      abort()
    }
    return coordinator
  }()
    
    
  init() {
    var _ = persistentStoreCoordinator
    let name = managedObjectContext.name
    log.info(name ?? "noname")
    addModule(module: MMD.init())
  }
}

extension ModuleStorage: ModuleStorageInterface {
  func addModule(module: MMD) {
    log.info(managedObjectModel.entities.first?.properties)
  }
}

