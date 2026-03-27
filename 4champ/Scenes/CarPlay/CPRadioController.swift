//
//  CPRadioView.swift
//  ampplayer
//
//  Copyright © 2026 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import CarPlay

class CPRadioController: NSObject {
  weak var interfaceController: CPInterfaceController?
  weak var playQueueController: CPPlayQueueController?
  var template = CPGridTemplate.init(title: "Radio", gridButtons: [])
  var badgeValue: Int = 0
  var customSelection = Radio.CustomSelection.init(name: "Radio_Custom".l13n(), ids: [])
  
  init(interfaceController: CPInterfaceController, playQueueController: CPPlayQueueController) {
    super.init()
    self.interfaceController = interfaceController
    self.playQueueController = playQueueController
    RadioInteractor.sharedInstance.addPresenter(self)
    update()
  }
    
  func cleanup() {
    log.debug("")
    RadioInteractor.sharedInstance.removePresenter(self)
  }
  
  func handleChannelSelection(_ button: CPGridButton, for channel: RadioChannel) {
    log.debug("")
    var request = Radio.Control.Request(state: .on, channel: channel)
    if channel == .custom {
      request.customSelection = RadioInteractor.sharedInstance.customSelection
    }
    _ = RadioInteractor.sharedInstance.controlRadio(request: request)
    update()
  }
  
  func createChannelGridButton(for channel: RadioChannel) -> CPGridButton {
    log.debug("")
    var imageSize = CGSize.init(width: 30, height: 30)
    if #available(iOS 26.0, *) {
      imageSize = CPGridTemplate.maximumGridButtonImageSize
    }

    let radioIcon = UIImage.init(named: "radio")?.resizeImageWith(newSize: imageSize).withTintColor(.label, renderingMode: .alwaysTemplate) ?? UIImage()
    var channelIcon = radioIcon

    var titleVariants: [String] = []
    var newChannelText = "Radio_New".l13n()

    switch channel {
    case .custom:
      titleVariants = [RadioInteractor.sharedInstance.customSelection.name]
    case .all:
      titleVariants = ["Radio_All".l13n()]
    case .local:
      titleVariants = ["Radio_Local".l13n()]
    case .new:
      if badgeValue > 0 {
        let badgeText = badgeValue < 100 ? " (\(badgeValue))" : " (99+)"
        newChannelText += badgeText
        channelIcon = radioIcon.withBadge()
      }
      titleVariants = [newChannelText, "Radio_New".l13n()]
    }
    
    if channel == RadioInteractor.sharedInstance.channel && ModulePlayer.sharedInstance.radioOn {
      titleVariants = titleVariants.map { "\($0) ♫" }
    }
    
    return CPGridButton(titleVariants: titleVariants, image: channelIcon) { [weak self] button in
      if let self = self {
        self.handleChannelSelection(button, for: channel)
      }
    }
  }
  
  func update() {
    log.debug("")
    
    let all = createChannelGridButton(for: .all)
    let new = createChannelGridButton(for: .new)
    let local = createChannelGridButton(for: .local)
    let custom = createChannelGridButton(for: .custom)
    if badgeValue > 0 {
      template.showsTabBadge = true
    } else {
      template.showsTabBadge = false
    }
    template.updateGridButtons([all, new, local, custom])
  }
  
  func showAlert(_ title: String) {
    log.debug("")
    let alertTemplate = CPAlertTemplate.init(titleVariants: [title], actions: [CPAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
      self?.interfaceController?.dismissTemplate(animated: true, completion: self?.interfaceController?.completionHandler)
    })])
    interfaceController?.presentTemplate(alertTemplate, animated: true, completion: self.interfaceController?.completionHandler)
  }
}

// MARK: RadioPresentationLogic
extension CPRadioController: RadioPresentationLogic {
  var presenterId: String { "Carplay-RadioController" }
  
  func presentControlStatus(status: RadioStatus) {
    log.debug("status is \(status)")
    switch status {
    case .fetching:
      return
    case .noModulesAvailable:
      showAlert("Radio_NoLocalModules".l13n())
    case .noSelectionAvailable:
      showAlert("Radio_NoSelection".l13n())
    case .on:
      let playing = ModulePlayer.sharedInstance.currentModule != nil
      let lastTemplate = interfaceController?.templates.last
      if playing && lastTemplate != CPNowPlayingTemplate.shared && lastTemplate != playQueueController?.template {
        interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: interfaceController?.completionHandler)
      }
      update()
    case .off:
      let lastTemplate = interfaceController?.templates.last
      if lastTemplate == CPNowPlayingTemplate.shared || lastTemplate == playQueueController?.template {
        interfaceController?.popToRootTemplate(animated: false, completion: interfaceController?.completionHandler)
      }
      update()
    default:
      update()
    }
  }
  
  func presentChannelBuffer(buffer: [MMD], history: [MMD]) {
    log.debug("")
    playQueueController?.updateUpNextTemplate(radioQueue: buffer)
  }
  
  func presentReplayer(name: String) {
  }
  
  func presentSessionHistoryInsert() {
  }
  
  func presentPlaybackTime(length: Int, elapsed: Int) {
  }
  
  func presentNotificationStatus(response: Radio.LocalNotifications.Response) {
  }
  
  func presentNewModules(response: Radio.NewModules.Response) {
    log.debug("")
    badgeValue = response.badgeValue
    update()
  }
  
}
