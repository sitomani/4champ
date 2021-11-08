//
//  RadioPresenter.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol RadioPresentationLogic
{
  func presentControlStatus(status: RadioStatus)
  func presentChannelBuffer(buffer: [MMD], history: [MMD])
  func presentSessionHistoryInsert()
  func presentPlaybackTime(length: Int, elapsed: Int)
  func presentNotificationStatus(response: Radio.LocalNotifications.Response)
  func presentNewModules(response: Radio.NewModules.Response)
}

enum NotificationState {
  case unknown
  case enabled
  case disabled
}

class RadioPresenter: RadioPresentationLogic
{
  weak var viewController: RadioDisplayLogic?
  
  // MARK: Do something
  func presentControlStatus(status: RadioStatus) {
    let vm = Radio.Control.ViewModel(status: status)
    DispatchQueue.main.async {
      self.viewController?.displayControlStatus(viewModel: vm)
    }
  }
  
  func presentChannelBuffer(buffer: [MMD], history: [MMD]) {
    log.debug("")
    var nextUp: String?
    if buffer.count > 1 {
      nextUp = "Radio_NextUp".l13n() + " " + String.init(format: "Radio_NByN".l13n(), buffer[1].name ?? "G_untitled".l13n(), buffer[1].composer ?? "G_untitled".l13n() )
    }
    
    let canStepBack = history.count > 0 && buffer.first != history.last
    let vm = Radio.ChannelBuffer.ViewModel(nowPlaying: buffer.first, nextUp: nextUp, historyAvailable: canStepBack)
    DispatchQueue.main.async {
      self.viewController?.displayChannelBuffer(viewModel: vm)
    }
  }

  func presentSessionHistoryInsert() {
    self.viewController?.displaySessionHistoryInsert()
  }
  
  func presentPlaybackTime(length: Int, elapsed: Int) {
    let timeLeft = length - elapsed
    let seconds = timeLeft % 60
    let minutes = (timeLeft - seconds) / 60
    let timeString = String.init(format: "%d:%02d", minutes, seconds)
    let vm = Radio.Playback.ViewModel(timeLeft: timeString)
    DispatchQueue.main.async {
      self.viewController?.displayPlaybackTime(viewModel: vm)
    }
  }
  
  func presentNotificationStatus(response: Radio.LocalNotifications.Response) {
    log.debug("")
    var vm = Radio.LocalNotifications.ViewModel(imageName: "notifications-add")

    if response.notificationsRequested {
      if response.notificationsEnabled {
        vm.imageName = "notifications-active"
      } else {
        vm.imageName = "notifications-off"
      }
    }
    DispatchQueue.main.async {
      self.viewController?.displayLocalNotificationStatus(viewModel: vm)
    }
  }
  
  func presentNewModules(response: Radio.NewModules.Response) {
    log.debug("")
    var text: String?
    switch response.badgeValue {
    case 0:
      text = nil
    case Constants.maxBadgeValue:
      text = "\(Constants.maxBadgeValue)+"
    default:
      text = "\(response.badgeValue)"
    }
    let vm = Radio.NewModules.ViewModel(badgeText: text)
    DispatchQueue.main.async {
      self.viewController?.displayNewModules(viewModel: vm)
    }
  }
}
