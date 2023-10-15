//
//  AppDelegate.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SwiftyBeaver
import AVFoundation
import Alamofire
import UserNotifications
import SwiftUI
import BackgroundTasks

// Global
let modulePlayer = ModulePlayer()
let moduleStorage = ModuleStorage()
let log = SwiftyBeaver.self
let settings = SettingsInteractor()
let shareUtil = ShareUtility()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  private var sharedMod: MMD?
  private lazy var dlController: DownloadController = DownloadController()
  private var bgQueue = OperationQueue()

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    Appearance.setup()
    setupLogging()
    setupAVSession()
    setupBackgroundTask()
    cleanupFiles()

    // UNCOMMENT BELOW TWO LINES TO TEST LOCAL NOTIFICATIONS
    //    settings.prevCollectionSize = 0
    //    settings.newestPlayed = 152890

    // Refresh the latest
    bgQueue.maxConcurrentOperationCount = 1
    bgQueue.addOperation(RefershLatestOperation())
    UIApplication.shared.beginReceivingRemoteControlEvents()

#if DEBUG
    ReviewActions.reset()
#endif
    return true
  }

  func setupBackgroundTask() {
    let scheduled = BGTaskScheduler.shared.register(forTaskWithIdentifier: "fourchamp.latest.refresh", using: nil) { task in
      log.debug("BG Task triggered")
      self.handleBackgroundTask(task: task)
    }
    if scheduled {
      log.debug("Task scheduled")
      scheduleAppRefresh()
    }
  }

  func setupAVSession() {
    let sess = AVAudioSession.sharedInstance()
    do {
      try sess.setCategory(.playback, mode: .default, options: [])
      try sess.setActive(true)
    } catch {
      log.error(error)
    }
  }

  func applicationWillResignActive(_ application: UIApplication) {
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
  }

  func applicationWillTerminate(_ application: UIApplication) {
    modulePlayer.cleanup()
  }

  func application(_ application: UIApplication,
                   continue userActivity: NSUserActivity,
                   restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL,
          let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
      return false
    }

    if components.path == "/mod", let idString = components.queryItems?.first?.value, let modId = Int(idString) {
      dlController.rootViewController = UIApplication.shared.windows[0].rootViewController
      dlController.show(modId: modId)
    }

    return true
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if url.scheme == "fourchamp" && url.host == "modules" {
      if let idString = url.path.split(separator: "/").first, let modId = Int(idString) {
        dlController.show(modId: modId)
      }
    } else {
      dlController.showImport(for: [url])
    }
    return true
  }

  func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
    return true
  }

  func scheduleAppRefresh() {
    let taskRequest = BGAppRefreshTaskRequest(identifier: "fourchamp.latest.refresh")
    taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 5*60)
    do {
      try BGTaskScheduler.shared.submit(taskRequest)
    } catch {
      print("Unable to schedule app refresh task: \(error)")
    }
  }

  func handleBackgroundTask(task: BGTask) {
    log.debug("")
    scheduleAppRefresh()

    let operation = RefershLatestOperation()
    bgQueue.addOperation(operation)

    task.expirationHandler = {
      operation.cancel()
    }

    operation.completionBlock = {
      task.setTaskCompleted(success: !operation.isCancelled)
    }
  }

  /// Set up SwiftyBeaver logging
  func setupLogging() {
    let console = ConsoleDestination()  // log to Xcode Console
    // use custom format and set console output to short time, log level & message
    console.format = "$DHH:mm:ss $d $L $N.$F $M"
    console.levelString.error = "🛑"
    console.levelString.warning = "🔶"
    console.levelString.info = "🔷"
    console.levelString.debug = "◾️"
    console.levelString.verbose = "◽️"
    log.addDestination(console)

    console.minLevel = .warning
#if DEBUG
    console.minLevel = .debug
#endif
    log.info("Logger initialized")
  }

  func cleanupFiles() {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    do {
      let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
      if let first = fileURLs.first {
        log.debug(first)
      }
      // process files
    } catch {
      log.error("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
    }
  }
}
