//
//  ModuleFetcher.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 27/09/2018.
//  Copyright © 2018 boogie. All rights reserved.
//

import Foundation
import Alamofire

enum FetcherState {
  case idle
  case resolvingPath
  case downloading(progress: Float)
  case unpacking
  case failed(err: Error?)
  case done(mmd: MMD)
}

protocol ModuleFetcherDelegate {
  func fetcherStateChanged(_ fetcher: ModuleFetcher, state: FetcherState)
}

class ModuleFetcher: Hashable {
  var delegate: ModuleFetcherDelegate?

  private var currentRequest: Alamofire.DataRequest?
  private var state: FetcherState = .idle {
    didSet {
      delegate?.fetcherStateChanged(self, state: state)
    }
  }
  
  convenience init(delegate: ModuleFetcherDelegate) {
    self.init()
    self.delegate = delegate
  }
  
  deinit {
    log.debug("")
  }
  
  static func == (left: ModuleFetcher, right: ModuleFetcher) -> Bool {
    return left === right
  }
  
  var hashValue: Int {
    return ObjectIdentifier(self).hashValue
  }
  
  func fetchModule(ampId: Int) {
    state = .resolvingPath
    let req = RESTRoutes.modulePath(id: ampId)
    currentRequest = Alamofire.request(req).validate().responseString { resp in
      guard resp.result.isSuccess else {
        log.error(resp.result.error!)
        self.state = .failed(err: resp.result.error)
        return
      }
      if let uriPath = resp.result.value,
        uriPath.count > 0,
        let modUrl = URL.init(string: uriPath) {
        self.fetchModule(modUrl: modUrl, id: ampId)
      }
    }
  }
  
  func cancel() {
    guard let req = currentRequest else { log.debug("No current request to cancel"); return }
    req.cancel()
    currentRequest = nil
  }
  
  private func fetchModule(modUrl: URL, id: Int) {
    log.debug("")
    state = .downloading(progress: 0)
    currentRequest = Alamofire.request(modUrl).validate().responseData { resp in
      guard resp.result.isSuccess else {
        log.error(resp.result.error!)
        self.state = .failed(err: resp.result.error)
        return
      }
      if let moduleData = resp.result.value {
        self.state = .unpacking
        if let moduleDataUnzipped = self.gzipInflate(data: moduleData) {
          var mmd = MMD.init(path: modUrl.path, modId: id)
          mmd.size = Int(moduleDataUnzipped.count / 1024)
          do {
            try moduleDataUnzipped.write(to: mmd.localPath!, options: .atomic)
          } catch {
            log.error("Could not write module data to file: \(error)")
          }
          self.state = .done(mmd: mmd)
          self.state = .idle
          self.currentRequest = nil
        }
      }
      }.downloadProgress { progress in
        var currentProg = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
        if currentProg == 1.0 {
          currentProg = 0
        }
        self.delegate?.fetcherStateChanged(self, state: FetcherState.downloading(progress: currentProg))
    }
  }
  
  private func gzipInflate(data: Data) -> Data? {
    if data.isGzipped {
      let inflated = try! data.gunzipped()
      return inflated
    }
    debugPrint("FAILED TO UNZIP")
    return data
  }
}
