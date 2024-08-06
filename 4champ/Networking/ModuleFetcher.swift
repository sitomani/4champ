//
//  ModuleFetcher.swift
//  ampplayer
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import Alamofire
import Gzip

/**
 ModuleFetcher states
 */
enum FetcherState {
  case idle
  case resolvingPath
  case downloading(progress: Float)
  case unpacking
  case failed(err: Error?)
  case done(mmd: MMD)
}

enum FetcherError: Error {
  case unsupportedFormat
}

/**
 ModuleFetcher state delegate.
 Implemented in classes that use a fetcher to download modules, e.g. RadioInteractor and SearchInteractor
 */
protocol ModuleFetcherDelegate: class {
  /**
   Fetcher calls delegate on state changes.
   - parameters:
      - fetcher: identifies the fetcher instance
      - state: identifies the state that fetcher changed into
 */
  func fetcherStateChanged(_ fetcher: ModuleFetcher, state: FetcherState)
}

/**
 Module Fetcher class
 Implements the flow for fetching modules, consisting of module download link fetching based on id,
 gzipped module downloading, unzipping and saving to local filesystem.
 */
class ModuleFetcher {
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

  /**
  Fetches a module based on Amiga Music Preservation module id. In case the module
     is available in local storage, will complete immediately through state change to `FetcherState.done`.
    - parameters:
        - ampId: Identifier of the module to download.
  */
  func fetchModule(ampId: Int) {
    state = .resolvingPath

    if let mmd = moduleStorage.getModuleById(ampId) {
      // update state asynchronously to avoid UI collisions on local collection radio fetch
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
        self.state = .done(mmd: mmd)
      })
        return
    }

    let req = RESTRoutes.modulePath(id: ampId)
    currentRequest = AF.request(req).validate().responseString { resp in
      switch resp.result {
      case .failure(let err):
        log.error(err)
        self.state = .failed(err: err)
      case .success(let uriPath):
        if uriPath.count > 0, let modUrl = URL.init(string: uriPath) {
          self.fetchModule(modUrl: modUrl, id: ampId)
        }
      }
    }
  }

  /**
  Cancels current fetch request if any.
  */
  func cancel() {
    guard let req = currentRequest else { log.debug("No current request to cancel"); return }
    req.cancel()
    currentRequest = nil
  }

  /**
  private function that fetches the module from the identified download link,
  unpacks it and saves to disk. After completion, reports the module metadata on the
  downloaded module through a state change to `FetcherState.done(mmd)`. In case
  of an error, a state change to `FetcherState.failed(error)` will be propagated.
   - parameters:
      - modUrl: URL of the module to download
      - id: numeric identifier of the module (needed for the module metadata object)
  */
  private func fetchModule(modUrl: URL, id: Int) {
    log.debug("")
    state = .downloading(progress: 0)
    currentRequest = AF.request(modUrl).validate().responseData { resp in
      if case .failure(let error) = resp.result {
        log.error(error)
        self.state = .failed(err: error)
        return
      }

      if case let .success(moduleData) = resp.result {
        self.state = .unpacking
        if let moduleDataUnzipped = self.gzipInflate(data: moduleData) {
          var mmd = MMD.init(path: modUrl.path, modId: id)
          mmd.size = Int(moduleDataUnzipped.count / 1024)

          // Make sure that we only process supported mods further
          guard mmd.supported() else {
            self.state = .failed(err: FetcherError.unsupportedFormat)
            return
          }
          do {
            // store to file and make sure it's not writing over an existing mod
            var numberExt = 0
            var localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
              .last!.appendingPathComponent(mmd.name).appendingPathExtension(mmd.type!)
            while FileManager.default.fileExists(atPath: localPath.path) {
                numberExt += 1
                let filename = mmd.name + "_\(numberExt)"
                localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .last!.appendingPathComponent(filename).appendingPathExtension(mmd.type!)
            }
            mmd.localPath = localPath
            try moduleDataUnzipped.write(to: mmd.localPath!, options: .atomic)
          } catch {
            log.error("Could not write module data to file: \(error)")
          }
          mmd.serviceId = .amp
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

  /**
  Unzips the module data using GzipSwift
   - parameters:
      - data: the gzipped module
   - returns: module data, unzipped
  */
  private func gzipInflate(data: Data) -> Data? {
    if data.isGzipped, let inflated = try? data.gunzipped() {
      return inflated
    }
    log.error("FAILED TO UNZIP")
    return data
  }
}

/**
 Hashable protocol extension to ModuleFetcher for keeping the fetchers in an array
 */
extension ModuleFetcher: Hashable {
  static func == (left: ModuleFetcher, right: ModuleFetcher) -> Bool {
    return left === right
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self).hashValue)
  }
}
