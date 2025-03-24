//
//  MainViewController.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftUI

protocol NowPlayingContainer {
  func toggleNowPlaying(_ value: Bool)
}

class MainViewController: UITabBarController {

  @IBOutlet weak var npView: NowPlayingView!

  var playingConstraint: NSLayoutConstraint?
  var notplayingConstraint: NSLayoutConstraint?

  override func viewDidLoad() {
    log.debug("")
    super.viewDidLoad()

    view.addSubview(npView)
    npView.translatesAutoresizingMaskIntoConstraints = false
    npView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    npView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    playingConstraint = npView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
    playingConstraint?.isActive = false
    notplayingConstraint = npView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    notplayingConstraint?.priority = .defaultLow
    notplayingConstraint?.isActive = true
    npView.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
    npView?.alpha = 0
    self.view.backgroundColor = Appearance.ampBgColor
    let tabBarAppearance: UITabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithDefaultBackground()
    tabBarAppearance.backgroundColor = Appearance.tabColor
    UITabBar.appearance().standardAppearance = tabBarAppearance

    if #available(iOS 15.0, *) {
      UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    let navBarAppearance: UINavigationBarAppearance = UINavigationBarAppearance()
    navBarAppearance.configureWithDefaultBackground()
    navBarAppearance.backgroundColor = Appearance.tabColor
    navBarAppearance.titleTextAttributes = [.foregroundColor: Appearance.barTitleColor,
                                            .font: UIFont.systemFont(ofSize: 16.0, weight: .heavy)]
    UINavigationBar.appearance().standardAppearance = navBarAppearance

    if #available(iOS 15.0, *) {
      UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }

    self.becomeFirstResponder()
    modulePlayer.addPlayerObserver(self)
    moduleStorage.addStorageObserver(self)
    UNUserNotificationCenter.current().delegate = self

    let lpr = UILongPressGestureRecognizer(target: self, action: #selector(showPlaylistPicker(_:)))
    npView?.addGestureRecognizer(lpr)

    let titles = ["TabBar_Local", "TabBar_Playlist", "TabBar_Search", "TabBar_Radio", "TabBar_About"]
    for tab in tabBar.items! {
      if let index = tabBar.items!.index(of: tab) {
        tab.title = titles[index].l13n()
      }
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
      traitOverrides.horizontalSizeClass = .unspecified
      if ProcessInfo.processInfo.isiOSAppOnMac {
        self.mode = .tabSidebar
        self.sidebar.isHidden = true
      }
    }
    super.viewWillAppear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    log.debug("")

    // Try to recover from potential database migration error
    if moduleStorage.coordinatorError != nil {
      showMigrationFailureDialog()
    }
  }

  func showMigrationFailureDialog() {
    let migrationAlert = UIAlertController.init(title: "Local_Database_Error_Title".l13n(),
                                                message: "Local_Database_Error_Text".l13n(),
                                                preferredStyle: .alert)
    migrationAlert.addAction(UIAlertAction.init(title: "Local_Database_Error_Try_Fix".l13n(),
                                                style: .default,
                                                handler: { _ in
      moduleStorage.rebuildDatabaseFromDisk()
    }))
    migrationAlert.addAction(UIAlertAction.init(title: "Local_Database_Error_Nvm".l13n(), style: .cancel, handler: { _ in
      moduleStorage.resetCoordinatorError()
    }))
    present(migrationAlert, animated: true)
  }

  func toggleNowPlaying(_ value: Bool) {
    log.debug("")

    UIView.animate(withDuration: 0.15) {
      self.playingConstraint?.isActive = value
      self.npView?.alpha = CGFloat(value == true ? 1 : 0)
      self.view.layoutIfNeeded()
    }

    for ctl in self.children {
      if let navCtl = ctl as? UINavigationController,
         let firstChild = navCtl.topViewController as? NowPlayingContainer {
        firstChild.toggleNowPlaying(value)
      }
    }
  }

  override func remoteControlReceived(with event: UIEvent?) {
    guard let event = event else {
      return
    }
    switch event.subtype {
    case .remoteControlPlay:
      modulePlayer.resume()
    case .remoteControlPause:
      modulePlayer.pause()
    case .remoteControlStop:
      modulePlayer.stop()
    case .remoteControlNextTrack:
      modulePlayer.playNext()
    case .remoteControlPreviousTrack:
      modulePlayer.playPrev()
    default:
      log.debug("remote control event \(event.subtype) not handled")
    }
  }

  @IBAction func togglePlay(_ sender: UIButton) {
    if modulePlayer.status == .paused {
      modulePlayer.resume()
    } else {
      modulePlayer.pause()
    }
  }

  @IBAction func showVisualizer(_ sender: UIButton) {
    log.debug("")
    if self.presentedViewController == nil {
      performSegue(withIdentifier: "ToVisualizer", sender: self)
      ReviewActions.increment()
    }
  }

  @objc func showPlaylistPicker(_ sender: UIGestureRecognizer) {
    guard sender.state == UIGestureRecognizer.State.began, let mmd = modulePlayer.currentModule else {
      return
    }

    let hvc = PlaylistSelectorStore.buildPicker(module: mmd)
    present(hvc, animated: true, completion: nil)
  }

  @IBAction func saveModule(_ sender: UIButton) {
    log.debug("")
    guard let mod = modulePlayer.currentModule else {
      log.error("no current module => cannot save")
      return
    }
    moduleStorage.addModule(module: mod)
    npView.setModule(mod)
  }

  @IBAction func faveModule(_ sender: UIButton) {
    guard let mod = modulePlayer.currentModule else {
      log.error("no current module => cannot toggle favorite")
      return
    }
    if let updated = moduleStorage.toggleFavorite(module: mod) {
      npView.setModule(updated)
    }
  }

  @IBAction func shareModule(_ sender: UIButton) {
    guard let mod = modulePlayer.currentModule else {
      log.error("no current module => cannot toggle favorite")
      return
    }
    shareUtil.shareMod(mod: mod)
  }

}

extension MainViewController: ModulePlayerObserver {
  func moduleChanged(module: MMD, previous: MMD?) {
    log.info("\(module.name) (\(module.type!))")
    DispatchQueue.main.async {
      self.npView.setModule(module)
    }
  }

  func statusChanged(status: PlayerStatus) {
    log.info("\(status)")
    DispatchQueue.main.async {
      self.toggleNowPlaying(status == .playing || status == .paused)
      self.npView.playPauseButton?.isSelected = (status == .paused)
    }
  }

  func errorOccurred(error: PlayerError) {
    // nop at the moment
  }

  func queueChanged(changeType: QueueChange) {
    // nop at the moment
  }
}

extension MainViewController: ModuleStorageObserver {
  func metadataChange(_ mmd: MMD) {
    if modulePlayer.currentModule?.id == mmd.id {
      npView.setModule(mmd)
    }
  }

  func playlistChange() {
    // NOP
  }
}

extension MainViewController: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.badge, .sound])
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    selectedIndex = 2 // go to radio tab
    completionHandler()
  }
}
