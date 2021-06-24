//
//  DownloadHostingController.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 13.4.2020.
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import SwiftUI

enum ImportError: Error {
  case alreadyImported
  case importFailed
}

struct DownloadModel {
  var module: MMD
  var summary: String?
  var importIds: [Int] = []
  var importResults: [ImportResultType] = []
  var progress: Float
  var error: Error?
  
  func statusText() -> String {
    if progress == 1.0 {
      return "ShareDialog_DownloadComplete".l13n()
    }
    if let err = error {
      if (err as? ImportError) == ImportError.alreadyImported {
        return "Local_Import_None".l13n()
      }
      return "Error"
    }
    return "Search_Downloading".l13n()
  }
  
  func displayName() -> String {
    if importResults.count > 0 {
      let alreadyImported = importResults.filter { $0 == .alreadyImported }.count
      let unknown = importResults.filter { $0 == .unknownType }.count
      
      var msg = ""
      if alreadyImported > 0 {
        msg += "\(alreadyImported) file(s) already in database"
      }
      
      if unknown > 0 {
        msg += "\n\(unknown) unknown file(s)\n"
      }
      if msg.count > 0 {
        return msg
      }
    }

    if let name = module.name, let composer = module.composer {
      if composer.count > 0 {
        return "\(name) by \(composer)"
      } else {
        return "\(name)"
      }
    }
    return "..."
  }
}

class DownloadController: ObservableObject {
  @Published var model: DownloadModel = DownloadModel(module: MMD(), progress: 0.0)
  
  lazy var hostingVC: UIHostingController<DownloadView> = UIHostingController<DownloadView>(rootView: DownloadView(store: self))
  weak var rootViewController: UIViewController?
  private var showing: Bool = false
  
  convenience init(rootVC: UIViewController) {
    self.init()
    self.rootViewController = rootVC
  }
  
  func show(modId: Int) {
    log.debug("")
    rootViewController = ShareUtility.topMostController()
    let queuedMod = modulePlayer.playQueue.first { modId == $0.id }
    if let mod = queuedMod {
      model.progress = 1.0
      model.module = mod
    } else if let mod = moduleStorage.getModuleById(modId) {
      model.progress = 1.0
      model.module = mod
    } else {
      let fetcher = ModuleFetcher(delegate: self)
      fetcher.fetchModule(ampId: modId)
    }
    showing = true
    hostingVC.view.backgroundColor = .clear
    rootViewController?.present(hostingVC, animated: true, completion: nil)
  }
  
  func showSingleImport(for url: URL) {
    log.debug("")
    rootViewController = ShareUtility.topMostController()
    var result: ImportResultType? = .unknownType
    if let mod = importModule(at: url, &result) {
      model.progress = 1.0
      model.module = mod
      model.error = nil
      model.importResults = [result!]
      model.importIds = [mod.id!]
    } else {
      model.importResults = [result!]
      switch(result) {
      case .alreadyImported:
        model.error = ImportError.alreadyImported
      case .importFailed:
        model.error = ImportError.importFailed
      default:
        log.debug("noop")
      }
    }
    showing = true
    hostingVC.view.backgroundColor = .clear
    rootViewController?.present(hostingVC, animated: true, completion: nil)
    
  }
  
  func dismiss() {
    log.debug("")
    discardModule()
    dismissView()
  }
  
  func play() {
    log.debug("")
    modulePlayer.play(mmd: model.module)
    dismissView()
  }
  
  func keep() {
    log.debug("")
    if model.module.hasBeenSaved() {
      return
    }
    moduleStorage.addModule(module: model.module)
    dismissView()
  }
  
  func assignComposer() {
    let vm = buildImportViewModel()
    rootViewController?.dismiss(animated: true, completion: {
                                  self.displayAssignDialog(viewModel: vm)
                                  self.showing = false })
  }
  
  func dismissView() {
    log.debug("")
    rootViewController?.dismiss(animated: true, completion: { self.showing = false })
  }
  
  func swipeDismissed() {
    log.debug("")
    if showing {
      discardModule()
      showing = false
    }
  }
  
  private func doAssignComposer(request: Local.Assign.Request) {
    request.moduleIds.forEach {
      if let modInfo = moduleStorage.fetchModuleInfo($0) {
        modInfo.modAuthor = request.composerName
      }
    }
    moduleStorage.saveContext()
  }
  
  private func buildImportViewModel() -> Local.Import.ViewModel {
    let l13nkey: String
    switch model.importIds.count {
    case 0:
      l13nkey = "Local_Import_None"
    case 1:
      l13nkey = "Local_Import_One"
    default:
      l13nkey = "Local_Import_Multiple"
    }
    let summary = String.init(format: l13nkey.l13n(), "\(model.importIds.count)")
    let alreadyImported = model.importResults.filter { $0 == .alreadyImported }.count
    let unknown = model.importResults.filter { $0 == .unknownType }.count
    
    var msg = ""
    if alreadyImported > 0 {
      msg += "\(alreadyImported) file(s) already in database"
    }
    
    if unknown > 0 {
      msg += "\n\(unknown) unknown file(s)\n"
    }
    
    let vm = Local.Import.ViewModel(summary: summary, modulenames: msg, moduleIds: model.importIds)
    return vm
  }
  
  private func displayAssignDialog(viewModel: Local.Import.ViewModel) {
    let av = UIAlertController.init(title: "Local_Import_Assign".l13n(), message: viewModel.summary, preferredStyle: .alert)
    av.addTextField { (tf) in
      tf.placeholder = "Local_Import_Composer".l13n()
    }
    
    av.addAction(UIAlertAction.init(title: "G_OK".l13n(), style: .default, handler: { [unowned av] (action) in
      if let tf = av.textFields, let composerName = tf[0].text {
        let request = Local.Assign.Request(moduleIds: viewModel.moduleIds, composerName: composerName)
        self.doAssignComposer(request: request)
      }
    }))
    av.addAction(UIAlertAction.init(title: "G_Cancel".l13n(), style: .cancel, handler: nil))
    rootViewController?.present(av, animated: true)
  }
  
  private func importModule(at url: URL, _ status: inout ImportResultType?) -> MMD? {
    var pathElements = url.path.split(separator: "/")
    status = .unknownType
    guard pathElements.count > 2 else {
      return nil
    }
    let filename = String(pathElements.popLast()!)
    
    guard let suffix = filename.split(separator: ".").last else {
      return nil
    }
    
    let filetype = String(suffix).uppercased()
    guard MMD.supportedTypes.contains(filetype) else {
      return nil
    }
    
    guard moduleStorage.fetchModuleInfoByKey(filename) == nil else {
      log.info("File \(filename) already imported")
      // already imported file with this name
      status = .alreadyImported
      return nil
    }
    
    var mmd = MMD.init()
    mmd.downloadPath = nil
    mmd.name = filename
    mmd.type = filetype
    mmd.composer = ""
    mmd.serviceId = .local
    mmd.serviceKey = filename
    
    //store to file and make sure it's not writing over an existing mod
    var numberExt = 0
    var localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(mmd.name!).appendingPathExtension(mmd.type!)
    while FileManager.default.fileExists(atPath: localPath.path) {
      numberExt += 1
      let filename = mmd.name! + "_\(numberExt)"
      localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(filename).appendingPathExtension(mmd.type!)
    }
    
    // Copy to documents dir from the picker temp folder
    do {
      try FileManager.default.copyItem(at: url, to: localPath)
      let attrs = try FileManager.default.attributesOfItem(atPath: localPath.path)
      mmd.size = ((attrs[FileAttributeKey.size] as? Int) ?? 0) / 1024
    } catch {
      status = .importFailed
      return nil
    }
    
    mmd.localPath = localPath
    mmd.id = moduleStorage.getNextModuleId(service: .local)
    moduleStorage.addModule(module: mmd)
    status = .importSuccess
    return mmd
  }
  
  private func discardModule() {
    if model.module.hasBeenSaved() == false {
      log.debug("")
      if let url = model.module.localPath {
        log.info("Deleting module \(url.lastPathComponent)")
        do {
          try FileManager.default.removeItem(at: url)
        } catch {
          log.error("Deleting file at \(url) failed, \(error)")
        }
      }
    }
  }
  
}

extension DownloadController: ModuleFetcherDelegate {
  func fetcherStateChanged(_ fetcher: ModuleFetcher, state: FetcherState) {
    switch state {
    case .done(let mmd):
      self.model = DownloadModel(module: mmd, progress: 1.0, error: nil)
    case .downloading(let progress):
      let model = DownloadModel(module: MMD(), progress: progress, error: nil)
      self.model = model
    case .failed(let err):
      model.error = err
    default:
      log.verbose("noop")
    }
  }
}

