//
//  AppDelegate.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import UserNotifications
import SwiftUI
import BackgroundTasks

// Global
let modulePlayer = ModulePlayer.sharedInstance
let moduleStorage = ModuleStorage()
let log = AMPLogger()
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
    setupAVSession()
    setupBackgroundTask()
    cleanupFiles()
    
    // UNCOMMENT BELOW TWO LINES TO TEST LOCAL NOTIFICATIONS
    //        settings.prevCollectionSize = 0
    //        settings.newestPlayed = 180330
    
    // Refresh the latest
    bgQueue.maxConcurrentOperationCount = 1
    bgQueue.addOperation(RefreshLatestOperation())
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
    
    // Setup remote command center for CarPlay and lock screen controls
    setupRemoteCommandCenter()
  }
  
  func setupRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()
    
    commandCenter.playCommand.isEnabled = true
    commandCenter.playCommand.addTarget { _ in
      modulePlayer.resume()
      return .success
    }
    
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.pauseCommand.addTarget { _ in
      modulePlayer.pause()
      return .success
    }
    
    commandCenter.stopCommand.isEnabled = true
    commandCenter.stopCommand.addTarget { _ in
      modulePlayer.stop()
      return .success
    }
    
    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.nextTrackCommand.addTarget { _ in
      modulePlayer.playNext()
      return .success
    }
    
    commandCenter.previousTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.addTarget { _ in
      modulePlayer.playPrev()
      return .success
    }
    
    // Toggle play/pause command
    commandCenter.togglePlayPauseCommand.isEnabled = true
    commandCenter.togglePlayPauseCommand.addTarget { _ in
      if modulePlayer.status == .paused {
        modulePlayer.resume()
      } else {
        modulePlayer.pause()
      }
      return .success
    }
    
    // Change playback position command (for scrubbing in CarPlay)
    commandCenter.changePlaybackPositionCommand.isEnabled = true
    commandCenter.changePlaybackPositionCommand.addTarget { event in
      guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
        return .commandFailed
      }
      modulePlayer.renderer.setCurrentPosition(Int32(positionEvent.positionTime))
      return .success
    }
    
    // loop command
    commandCenter.changeRepeatModeCommand.isEnabled = true
    commandCenter.changeRepeatModeCommand.addTarget { _ in
      if let currentModule = modulePlayer.currentModule {
        _ = moduleStorage.toggleLoop(module: currentModule)
      }
      return .success
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
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first else {
        return false
      }
      dlController.rootViewController = window.rootViewController
      dlController.show(modId: modId)
    }
    return true
  }
  
  func application(_ application: UIApplication,
                   configurationForConnecting connectingSceneSession: UISceneSession,
                   options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    
    if connectingSceneSession.role == .carTemplateApplication {
      let sceneConfig = UISceneConfiguration(name: "TemplateSceneConfiguration", sessionRole: connectingSceneSession.role)
      sceneConfig.delegateClass = TemplateApplicationSceneDelegate.self
      return sceneConfig
    }
    
    let sceneConfig = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    sceneConfig.delegateClass = SceneDelegate.self
    return sceneConfig
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
    
    let operation = RefreshLatestOperation()
    bgQueue.addOperation(operation)
    
    task.expirationHandler = {
      operation.cancel()
    }
    
    operation.completionBlock = {
      task.setTaskCompleted(success: !operation.isCancelled)
    }
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
