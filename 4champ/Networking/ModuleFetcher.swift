//
//  ModuleFetcher.swift
//  ampplayer
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
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
class ModuleFetcher: NSObject {
  var delegate: ModuleFetcherDelegate?

  private var currentTask: Task<Sendable, Error>?
  private var downloadTask: URLSessionDownloadTask?
  private var state: FetcherState = .idle {
    didSet {
      let state = state
      DispatchQueue.main.async {
        self.delegate?.fetcherStateChanged(self, state: state)
      }
    }
  }
  /// Holds the currently downloading module id
  private var targetModuleId: Int?

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

    currentTask = Task {
      do {
        let client = NetworkClient()
        let requ = APIModulePathRequest(moduleId: ampId)
        let resp = try await client.send(requ)
        if resp.count > 0, let modUrl = URL.init(string: resp) {
          self.fetchModule(modUrl: modUrl, id: ampId)
        }
      } catch {
        state = .failed(err: error)
        log.error(error)
      }
      return
    }
  }

  /**
   Cancels current fetch request if any.
   */
  func cancel() {
    currentTask?.cancel()
    downloadTask?.cancel()
    currentTask = nil
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
    targetModuleId = id

    let configuration = URLSessionConfiguration.default
    let operationQueue = OperationQueue()
    let session = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)

    downloadTask = session.downloadTask(with: modUrl)
    downloadTask?.resume()
    return
  }

}

extension ModuleFetcher: URLSessionDownloadDelegate {
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    log.debug("Downloaded module to \(location)")
    self.state = .unpacking
    if let moduleData = try? Data(contentsOf: location),
        let moduleDataUnzipped = self.gzipInflate(data: moduleData),
        let modId = targetModuleId {
      var mmd = MMD.init(path: downloadTask.originalRequest!.url!.path, modId: modId)
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
      mmd.serviceId = ModuleService.amp
      self.state = .done(mmd: mmd)
      self.state = .idle
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
  
  func urlSession(_ session: URLSession,
                  downloadTask: URLSessionDownloadTask,
                  didWriteData bytesWritten: Int64,
                  totalBytesWritten: Int64,
                  totalBytesExpectedToWrite: Int64) {
    var currentProg = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
    if currentProg == 1.0 {
      currentProg = 0
    }
    state = .downloading(progress: currentProg)
  }
}
