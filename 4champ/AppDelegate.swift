//
//  AppDelegate.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SwiftyBeaver
import AVFoundation

// Global
let modulePlayer = ModulePlayer()
let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    Appearance.setup()
    setupLogging()
    setupAVSession()
    cleanupFiles()
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
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    //Start receiving remote control events
    UIApplication.shared.beginReceivingRemoteControlEvents()
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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

  /// Until local module database support has been implemented,
  /// clean the previous session files
  func cleanupFiles() {
    log.debug("")
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    do {
      let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
      for url in fileURLs {
        log.debug(url)
        do {
          try FileManager.default.removeItem(at: url)
        } catch {
          log.error("Deleting file at \(url) failed, \(error)")
        }
      }
    } catch {
      print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
    }
  }
}

