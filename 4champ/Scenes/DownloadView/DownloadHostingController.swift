//
//  DownloadHostingController.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 13.4.2020.
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum ImportResultType {
  case importSuccess
  case alreadyImported
  case unknownType
  case importFailed
}

enum ImportType {
  case unknown
  case universalLink
  case documentLink
}

enum ImportError: Error {
  case alreadyImported
  case importFailed
}

struct DownloadModel {
  var status: String = "Search_Downloading".l13n()
  var summary: String = "..."
  var importIds: [Int] = []
  var importResults: [ImportResultType] = []
  var importType: ImportType = .unknown
  var progress: Float = 0
  var error: Error?
}

class DownloadController: NSObject, ObservableObject {
  @Published var model: DownloadModel = DownloadModel()

  lazy var hostingVC: UIHostingController<DownloadView> = UIHostingController<DownloadView>(rootView: DownloadView(store: self))
  weak var rootViewController: UIViewController?
  private var showing: Bool = false
  private var documentPickerVC: UIDocumentPickerViewController?
  private var downloadedModule: MMD?
  private var addToCurrentPlaylist: Bool = false

  convenience init(rootVC: UIViewController) {
    self.init()
    self.rootViewController = rootVC
  }

  func selectImportModules(addToPlaylist: Bool = false) {
    self.addToCurrentPlaylist = addToPlaylist
    if documentPickerVC == nil {

      if #available(iOS 14, *) {
        let supportedTypes: [UTType] = [UTType.item]
        documentPickerVC = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
      } else {
        let supportedTypes: [String] = ["public.item"]
        documentPickerVC = UIDocumentPickerViewController(documentTypes: supportedTypes, in: .import)
      }
      documentPickerVC?.delegate = self
      documentPickerVC?.modalPresentationStyle = .formSheet
      documentPickerVC?.allowsMultipleSelection = true
    }
    rootViewController?.present(documentPickerVC!, animated: true)
  }

  func show(modId: Int) {
    log.debug("")
    model.importType = .universalLink
    rootViewController = ShareUtility.topMostController()
    let queuedMod = modulePlayer.playQueue.first { modId == $0.id }
    if let mod = queuedMod {
      model.progress = 1.0
      model.status = "ShareDialog_DownloadComplete".l13n()
      model.summary = buildSummary(mod: mod)
    } else if let mod = moduleStorage.getModuleById(modId) {
      model.progress = 1.0
      model.status = "ShareDialog_DownloadComplete".l13n()
      model.summary = buildSummary(mod: mod)
    } else {
      let fetcher = ModuleFetcher(delegate: self)
      fetcher.fetchModule(ampId: modId)
    }
    showing = true
    hostingVC.view.backgroundColor = .clear
    rootViewController?.present(hostingVC, animated: true, completion: nil)
  }

  private func buildSummary(mod: MMD) -> String {
    if let composer = mod.composer, composer.trimmingCharacters(in: CharacterSet.whitespaces).count > 0 {
      return "\(mod.name) by \(composer)"
    }
    return mod.name
  }

  func showImport(for urls: [URL]) {
    log.debug("")
    rootViewController = ShareUtility.topMostController()
    model.importResults = []
    model.importType = .documentLink
    model.importIds.removeAll()
    showing = true
    hostingVC.view.backgroundColor = .clear
    rootViewController?.present(hostingVC, animated: true, completion: nil)

    for url in urls {
      handleImport(for: url)
    }

    updateStatusAndSummary()
  }

  private func handleImport(for url: URL) {
    var result: ImportResultType? = .unknownType
    if let mod = importModule(at: url, &result) {
      if addToCurrentPlaylist, let modId = mod.id, let modInfo = moduleStorage.fetchModuleInfo(modId) {
        moduleStorage.currentPlaylist?.addToModules(modInfo)
      }
      model.progress = 1.0
      model.error = nil
      model.importResults.append(.importSuccess)
      model.importIds.append(mod.id!)
    } else {
      model.importResults.append(result!)
    }
  }

  private func updateStatusAndSummary() {
    let imported = model.importResults.filter { $0 == .importSuccess }.count

    let l13nkey: String
    switch imported {
    case 0:
      l13nkey = "Local_Import_None"
    case 1:
      l13nkey = "Local_Import_One"
    default:
      l13nkey = "Local_Import_Multiple"
    }
    model.status = String.init(format: l13nkey.l13n(), "\(imported)")

    if model.importIds.count == 1 && model.importResults[0] == .importSuccess {
      if let mod = moduleStorage.getModuleById(model.importIds[0]) {
        model.summary = buildSummary(mod: mod)
      }
    } else {
      updateSummary()
    }
  }

  private func updateSummary() {
    let imported = model.importResults.filter { $0 == .importSuccess }.count
    let alreadyImported = model.importResults.filter { $0 == .alreadyImported }.count
    let unknown = model.importResults.filter { $0 == .unknownType }.count

    var summaryItems: [String] = []

      if imported > 0 {
        if alreadyImported > 0 || unknown > 0 {
          summaryItems.append(String.init(format: "Local_Import_Imported".l13n(), "\(imported)"))
        } else {
          let names: [String] = model.importIds.compactMap {
            if let mod = moduleStorage.getModuleById($0) {
              return mod.name
            }
            return nil
          }
          if names.count > 10 {
            summaryItems.append(names.joined(separator: ", ") + ", ...")

        } else {
          summaryItems.append(names.joined(separator: ", "))
        }
      }
    }

    if alreadyImported > 0 {
      let prefixString = summaryItems.count > 0 ? "\n" : ""
      summaryItems.append(prefixString + String.init(format: "Local_Import_Already_In".l13n(), "\(alreadyImported)"))
    }

    if unknown > 0 {
      let prefixString = summaryItems.count > 0 ? "\n" : ""
      summaryItems.append(prefixString + String.init(format: "Local_Import_Unknown".l13n(), "\(unknown)"))
    }
    model.summary = summaryItems.joined(separator: ", ")
  }

  func dismiss() {
    log.debug("")
    discardModule()
    dismissView()
  }

  func play() {
    log.debug("")
    switch model.importType {
    case .universalLink:
      if let mmd = downloadedModule {
        modulePlayer.play(mmd: mmd)
      }
    case .documentLink:
      model.importIds.forEach {
        var playStarted = false
        if let mmd = moduleStorage.getModuleById($0) {
          if modulePlayer.playQueue.contains(mmd) == false {
            modulePlayer.playQueue.append(mmd)
          }
          if !playStarted {
            modulePlayer.play(mmd: mmd)
            playStarted = true
          }
        }
      }
    default:
      log.debug("noop")
    }
    dismissView()
  }

  func keep() {
    log.debug("")
    guard let modId = model.importIds.first, let mod = moduleStorage.getModuleById(modId) else {
      return
    }
    if mod.hasBeenSaved() {
      return
    }
    moduleStorage.addModule(module: mod)
    dismissView()
  }

  func assignComposer() {
    rootViewController?.dismiss(animated: false, completion: {
                                  self.displayAssignDialog()
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

  private func displayAssignDialog() {
    let av = UIAlertController.init(title: "Local_Import_Assign".l13n(), message: model.status, preferredStyle: .alert)
    av.addTextField { (tf) in
      tf.placeholder = "Local_Import_Composer".l13n()
    }

    av.addAction(UIAlertAction.init(title: "G_OK".l13n(), style: .default, handler: { [unowned av] (_) in
      if let tf = av.textFields, let composerName = tf[0].text {
        let request = Local.Assign.Request(moduleIds: self.model.importIds, composerName: composerName)
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

    if let previouslyImported = moduleStorage.fetchModuleInfoByKey(filename) {
      log.info("File \(filename) already imported")
      // already imported file with this name
      status = .alreadyImported
      return MMD.init(cdi: previouslyImported)
    }

    var mmd = MMD.init()
    mmd.downloadPath = nil
    mmd.name = filename
    mmd.type = filetype
    mmd.composer = ""
    mmd.serviceId = .local
    mmd.serviceKey = filename

    guard let localPath = copyFileToDocumentsDirectory(from: url, with: &mmd, status: &status) else {
      return nil
    }

    mmd.localPath = localPath
    mmd.id = moduleStorage.getNextModuleId(service: .local)
    moduleStorage.addModule(module: mmd)
    status = .importSuccess
    return mmd
  }

  private func copyFileToDocumentsDirectory(from url: URL, with mmd: inout MMD, status: inout ImportResultType?) -> URL? {
    var numberExt = 0
    var localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .last!.appendingPathComponent(mmd.name).appendingPathExtension(mmd.type!)
    while FileManager.default.fileExists(atPath: localPath.path) {
      numberExt += 1
      let filename = mmd.name + "_\(numberExt)"
      localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .last!.appendingPathComponent(filename).appendingPathExtension(mmd.type!)
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

    return localPath
  }

  private func discardModule() {
    guard let modId = model.importIds.first, let mod = moduleStorage.getModuleById(modId) else {
      return
    }
    if mod.hasBeenSaved() == false {
      log.debug("")
      if let url = mod.localPath {
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
      self.model = DownloadModel(status: "ShareDialog_DownloadComplete".l13n(),
                                 summary: buildSummary(mod: mmd),
                                 importIds: [mmd.id!],
                                 importResults: [.importSuccess],
                                 importType: .universalLink,
                                 progress: 1.0,
                                 error: nil)
      downloadedModule = mmd
    case .downloading(let progress):
      let model = DownloadModel(progress: progress, error: nil)
      self.model = model
    case .failed(let err):
      model.error = err
    default:
      log.debug("noop")
    }
  }
}

extension DownloadController: UIDocumentPickerDelegate {

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    showImport(for: urls)
  }
}
