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

// Global
let modulePlayer = ModulePlayer()
let moduleStorage = ModuleStorage()
let log = SwiftyBeaver.self
let settings = SettingsInteractor()
let shareUtil = ShareUtility()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  private var _bgFetchCallback: ((UIBackgroundFetchResult) -> Void)?

  private var sharedMod: MMD?

  private lazy var dlController: DownloadController = DownloadController()

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    Appearance.setup()
    setupLogging()
    setupAVSession()
    cleanupFiles()
    // UNCOMMENT BELOW TWO LINES TO TEST LOCAL NOTIFICATIONS
    //    settings.prevCollectionSize = 0
    //    settings.newestPlayed = 152890

    updateLatest()
    UIApplication.shared.beginReceivingRemoteControlEvents()

    #if DEBUG
    ReviewActions.reset()
    #endif

    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    return true
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

  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    log.debug("performFetch")
    _bgFetchCallback = completionHandler
    updateLatest()
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

  func updateLatest() {
    log.debug("")
    let req = RESTRoutes.latestId
    AF.request(req).validate().responseString { resp in
      switch resp.result {
      case .failure:
        self._bgFetchCallback?(.noData)
        self._bgFetchCallback = nil
      case .success(let str):
        guard let collectionSize = Int(str) else { return }
        log.info("Collection Size: \(collectionSize)")
        self.updateCollectionSize(size: collectionSize)
      }
    }
  }

  func updateCollectionSize(size: Int) {
    log.debug("")
    settings.collectionSize = size
    let prevSize = settings.prevCollectionSize

    // Only fire the request once per a given collectionSize/diff
    if prevSize < size && settings.badgeCount < Constants.maxBadgeValue {
      let fmt = "Radio_Notification".l13n()
      let content = UNMutableNotificationContent()
      content.body = String.init(format: fmt, "\(settings.badgeCount)")
      content.categoryIdentifier = "newmodules"
      let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
      let req = UNNotificationRequest.init(identifier: "newmodules-usernotif", content: content, trigger: trigger)
      UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
      settings.prevCollectionSize = settings.collectionSize
      _bgFetchCallback?(.newData)
    } else {
      _bgFetchCallback?(.noData)
    }
    _bgFetchCallback = nil
  }
}
