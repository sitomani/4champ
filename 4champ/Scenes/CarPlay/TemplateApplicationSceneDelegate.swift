//
//  TemplateApplicationSceneDelegate.swift
//  ampplayer
//
//  Copyright © 2026 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import CarPlay
import MediaPlayer

class TemplateApplicationSceneDelegate: UIResponder {
  var interfaceController: CPInterfaceController?
  var sessionConfig: CPSessionConfiguration?
  var tabBarTemplate: CPTabBarTemplate?
  lazy var playlistsController = CPPlaylistsController(interfaceController: self.interfaceController!)
  lazy var playQueueController = CPPlayQueueController(interfaceController: self.interfaceController!)
  lazy var radioController = CPRadioController(interfaceController: self.interfaceController!, playQueueController: playQueueController)
}

extension TemplateApplicationSceneDelegate: CPTemplateApplicationSceneDelegate {
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
    log.debug("")
    self.interfaceController = interfaceController
    self.interfaceController?.delegate = self
    sessionConfig = CPSessionConfiguration(delegate: self)
    
    ModulePlayer.sharedInstance.addPlayerObserver(self)
    
    playQueueController.configureNowPlaying()
    tabBarTemplate = CPTabBarTemplate.init(templates: [radioController.template, playlistsController.listsTemplate])
    tabBarTemplate?.delegate = self
    radioController.update()
    interfaceController.setRootTemplate(tabBarTemplate!, animated: false, completion: self.interfaceController?.completionHandler)
    playlistsController.updatePlaylistsTemplate()

    if ModulePlayer.sharedInstance.renderer.isPlaying {
      interfaceController.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: self.interfaceController?.completionHandler)
    }
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnectInterfaceController interfaceController: CPInterfaceController) {
    log.debug("Template application scene did disconnect.")
    radioController.cleanup()
    playlistsController.cleanup()
  }
}

// MARK: - ModulePlayerObserver
extension TemplateApplicationSceneDelegate: ModulePlayerObserver {
  func statusChanged(status: PlayerStatus) {
    DispatchQueue.main.asyncAfter(deadline: .now()+0.3, execute: { [weak self] in
      self?.playlistsController.updateCurrentPlaylistTemplate()
      self?.playlistsController.updatePlaylistsTemplate()
    })
  }
  
  func moduleChanged(module: MMD, previous: MMD?) {
    log.debug("")
    playlistsController.updateCurrentPlaylistTemplate()
    playQueueController.updateUpNextTemplate()
    playQueueController.updateNowPlayingButtons()
  }
  
  func errorOccurred(error: PlayerError) {
  }
  
  func queueChanged(changeType: QueueChange) {
    log.debug("")
    playlistsController.updateCurrentPlaylistTemplate()
    playQueueController.updateUpNextTemplate()
  }
}

// MARK: - CPTabBarTemplateDelegate
extension TemplateApplicationSceneDelegate: CPTabBarTemplateDelegate {
  func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
    print("selected template \(selectedTemplate)")
  }
}

// MARK: - CPInterfaceControllerDelegate
extension TemplateApplicationSceneDelegate: CPInterfaceControllerDelegate {
  
  func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
    log.debug("\(type(of: aTemplate))")
    
    if aTemplate == radioController.template {
      aTemplate.tabTitle="TabBar_Radio".l13n()
    }
    if aTemplate == playlistsController.listsTemplate {
      aTemplate.tabTitle="PlaylistView_Playlists".l13n()
    }
  }
}

extension CPInterfaceController {
  func completionHandler(success: Bool, error: Error?) {
    if error != nil {
      log.debug("completionHandler: error: \(String(describing: error))")
    }
  }
}

extension TemplateApplicationSceneDelegate: CPSessionConfigurationDelegate {
  func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
    log.debug("userInf \(limitedUserInterfaces)")
  }

  func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, contentStyleChanged contentStyle: CPContentStyle) {
    log.debug("contentStyle: \(contentStyle)")
  }
}
