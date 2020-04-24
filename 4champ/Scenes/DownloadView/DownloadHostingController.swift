//
//  DownloadHostingController.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 13.4.2020.
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import SwiftUI

struct DownloadModel {
    var module: MMD
    var progress: Float
    var error: Error?
    
    func statusText() -> String {
        if progress == 1.0 {
            return "ShareDialog_DownloadComplete".l13n()
        }
        if error != nil {
            return "Error"
        }
        return "Search_Downloading".l13n()
    }
    
    func displayName() -> String {
        if let name = module.name, let composer = module.composer {
            return "\(name) by \(composer)"
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
        rootViewController = ShareUtility.topMostController()
        log.debug("")
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

