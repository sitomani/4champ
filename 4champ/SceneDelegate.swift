//
//  SceneDelegate.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 7.3.2020.
//

import Foundation
import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    log.warning("\(connectionOptions)")
    if let windowScene = scene as? UIWindowScene {
      let window = UIWindow(windowScene: windowScene)
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      let vc = storyboard.instantiateViewController(withIdentifier: "mainScreen")
      window.rootViewController = vc
      self.window = window
      window.makeKeyAndVisible()
    }
    
    let urlContexts = connectionOptions.urlContexts
    if !urlContexts.isEmpty {
      handleURLContexts(urlContexts) // Extract and process URLs
    }
    
  }
  
  private func handleURLContexts(_ contexts: Set<UIOpenURLContext>) {
    guard let context = contexts.first else { return }
    let url = context.url // The incoming URL (e.g., myapp://test)
    print("Handling URL: \(url)")
    
    DispatchQueue.main.async {
      // Get the download controller - you'll need access to it
      let dlController = DownloadController()
      if let windowScene = self.window?.windowScene,
         let window = windowScene.windows.first {
        dlController.rootViewController = window.rootViewController
      }
      
      if url.scheme == "fourchamp" && url.host == "modules" {
        if let idString = url.path.split(separator: "/").first, let modId = Int(idString) {
          dlController.show(modId: modId)
        }
      } else {
        dlController.showImport(for: [url])
      }
    }
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
    
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
    // Save changes in the application's managed object context when the application transitions to the background.
    //        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
  }
  
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    log.warning("\(URLContexts)")
    handleURLContexts(URLContexts)
  }
  
}
