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
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    modulePlayer.cleanup()
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    log.debug("performFetch")
    _bgFetchCallback = completionHandler
    updateLatest()
  }
  
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    
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
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.scheme == "fourchamp" && url.host == "modules" {
      if let idString = url.path.split(separator: "/").first, let modId = Int(idString) {
        dlController.show(modId: modId)
      }
      
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
        print(first)
      }
      // process files
    } catch {
      print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
    }
  }
  
  func updateLatest() {
    log.debug("")
    let req = RESTRoutes.latestId
    Alamofire.request(req).validate().responseString { resp in
      if let value = resp.result.value, let intValue = Int(value) {
        log.info("Collection Size: \(intValue)")
        self.updateCollectionSize(size: intValue)
      } else {
        self._bgFetchCallback?(.noData)
        self._bgFetchCallback = nil
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


