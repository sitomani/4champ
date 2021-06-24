//
//  ImportController.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 22.5.2021.
//  Copyright © 2021 boogie. All rights reserved.
//

import Foundation
import UIKit

enum ImportResultType {
  case importSuccess
  case alreadyImported
  case unknownType
  case importFailed
}

protocol ImportProtocol {
  func selectImportModules()
  func importModules(request: Local.Import.Request)
}

class ImportController:NSObject, ImportProtocol {
  weak var rootViewController: UIViewController?
  private var documentPickerVC: UIDocumentPickerViewController?
  
  convenience init(rootVC: UIViewController) {
    self.init()
    self.rootViewController = rootVC
  }
  
  func selectImportModules() {
    if documentPickerVC == nil {
      documentPickerVC = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
      documentPickerVC?.delegate = self
      documentPickerVC?.modalPresentationStyle = .formSheet
      documentPickerVC?.allowsMultipleSelection = true
    }
    rootViewController?.present(documentPickerVC!, animated: true)
  }
  
  func importModules(request: Local.Import.Request) {
    var imported: [MMD] = []
    var resultTypes: [ImportResultType] = []
    for url in request.urls {
      var result: ImportResultType? = .unknownType
      if let mod = importModule(at: url, &result) {
        imported.append(mod)
      }
      resultTypes.append(result ?? .unknownType)
    }
    presentImport(response: Local.Import.Response(modules: imported, importResults: resultTypes))
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
  func presentImport(response: Local.Import.Response) {
    let l13nkey: String
    switch response.modules.count {
    case 0:
      l13nkey = "Local_Import_None"
    case 1:
      l13nkey = "Local_Import_One"
    default:
      l13nkey = "Local_Import_Multiple"
    }
    let summary = String.init(format: l13nkey.l13n(), "\(response.modules.count)")
    let alreadyImported = response.importResults.filter { $0 == .alreadyImported }.count
    let unknown = response.importResults.filter { $0 == .unknownType }.count
    
    var msg = ""
    if alreadyImported > 0 {
      msg += "\(alreadyImported) file(s) already in database"
    }
    
    if unknown > 0 {
      msg += "\n\(unknown) unknown file(s)\n"
    }

    let vm = Local.Import.ViewModel(summary: summary, modulenames: msg, moduleIds: response.modules.map { $0.id!})
    displayImportResult(viewModel: vm)
  }
  
  func displayImportResult(viewModel: Local.Import.ViewModel) {
    rootViewController = ShareUtility.topMostController()
    
    let av = UIAlertController.init(title: viewModel.summary, message: viewModel.modulenames, preferredStyle: .alert)
    let assignAction = UIAlertAction.init(title: "Local_Import_Assign".l13n(), style: .default) { (action) in
      self.displayAssignDialog(viewModel: viewModel)
    }
    let okAction = UIAlertAction.init(title: "G_OK".l13n(), style: .default, handler: nil)
    let cancelAction = UIAlertAction.init(title: "Local_Import_Cancel".l13n(), style: .destructive, handler: { [weak self] (action) in
      self?.deleteModules(request: Local.Delete.Request(moduleIds: viewModel.moduleIds))
    })
    av.addAction(okAction)
    if viewModel.moduleIds.count > 0 {
      av.addAction(assignAction)
      av.addAction(cancelAction)
    }
    
    rootViewController?.present(av, animated: true)
  }
  
  private func displayAssignDialog(viewModel: Local.Import.ViewModel) {
    let av = UIAlertController.init(title: "Local_Import_Assign".l13n(), message: viewModel.summary, preferredStyle: .alert)
    av.addTextField { (tf) in
      tf.placeholder = "Local_Import_Composer".l13n()
    }
    
    av.addAction(UIAlertAction.init(title: "G_OK".l13n(), style: .default, handler: { [unowned av] (action) in
      if let tf = av.textFields, let composerName = tf[0].text {
        let request = Local.Assign.Request(moduleIds: viewModel.moduleIds, composerName: composerName)
        self.assignComposer(request: request)
      }
    }))
    av.addAction(UIAlertAction.init(title: "G_Cancel".l13n(), style: .cancel, handler: nil))
    rootViewController?.present(av, animated: true)
  }
  
  func deleteModules(request: Local.Delete.Request) {
    request.moduleIds.forEach {
      if let mod = moduleStorage.getModuleById($0) {
        moduleStorage.deleteModule(module: mod)
      }
    }
  }
  
  func assignComposer(request: Local.Assign.Request) {
    request.moduleIds.forEach {
      if let modInfo = moduleStorage.fetchModuleInfo($0) {
        modInfo.modAuthor = request.composerName
      }
    }
    moduleStorage.saveContext()
  }
}

extension ImportController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let request = Local.Import.Request(urls: urls)
    importModules(request: request)
  }
}
