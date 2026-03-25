//
//  CPPlayQueueController.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 15.3.2026.
//

import CarPlay

class CPPlayQueueController: NSObject {
  weak var interfaceController: CPInterfaceController?
  weak var tabBarTemplate: CPTabBarTemplate?
  var template = CPListTemplate.init(type: .playQueue)
  
  init(interfaceController: CPInterfaceController, tabBarTemplate: CPTabBarTemplate? = nil) {
    self.interfaceController = interfaceController
    self.tabBarTemplate = tabBarTemplate
  }
  
  func configureNowPlaying() {
    let nowPlayingTemplate = CPNowPlayingTemplate.shared
    nowPlayingTemplate.add(self)
    updateNowPlayingButtons()
    
    nowPlayingTemplate.isUpNextButtonEnabled = true
    nowPlayingTemplate.isAlbumArtistButtonEnabled = false
  }
  
  func showPlayQueue() {
    updateUpNextTemplate()
    interfaceController?.pushTemplate(template, animated: true, completion: interfaceController?.completionHandler)
  }
  
  func updateUpNextTemplate(radioQueue: [MMD] = []) {
    var queue: [MMD]
    if radioQueue.count > 0 {
      queue = radioQueue
    } else {
      queue = ModulePlayer.sharedInstance.playQueue
    }
    if let currentMod = ModulePlayer.sharedInstance.currentModule,
        let currentIndex = queue.firstIndex(where: { $0.id == currentMod.id }) {
      for _ in 0..<currentIndex+1 {
        let mmd = queue.removeFirst()
        if !ModulePlayer.sharedInstance.radioOn {
          queue.append(mmd)
        }
      }
    }
    let items: [CPSelectableListItem] = queue.map { mmd in
      let item: CPSelectableListItem = CPListItem.init(
        text: mmd.name,
        detailText: mmd.composer,
        image: UIImage.moduleIcon(for: mmd))
        item.handler = { _, completion in
          if let index = modulePlayer.playQueue.firstIndex(of: mmd) {
            modulePlayer.play(at: index)
          }
          completion()
        }
      if ModulePlayer.sharedInstance.currentModule?.id == mmd.id {
        (item as? CPListItem)?.isPlaying = true
      } else {
        (item as? CPListItem)?.isPlaying = false
      }
      return item
    }
    let sections: [CPListSection] = [CPListSection(items: items, header: "Radio_NextUp".l13n(), sectionIndexTitle: nil)]
    template.updateSections(sections)
  }
  
  func updateNowPlayingButtons() {
    var buttons: [CPNowPlayingButton] = []
    
    // Repeat button
    let mod = ModulePlayer.sharedInstance.currentModule
    let loopIcon = ModulePlayer.sharedInstance.currentModule?.loop ?? 0 > 0 ? "repeat.circle.fill" : "repeat.circle"
    let loopButton = CPNowPlayingImageButton(image: UIImage(systemName: loopIcon)!) { _ in
      if let mmd = mod {
        _ = moduleStorage.toggleLoop(module: mmd)
      }
      self.updateNowPlayingButtons()
    }
    loopButton.isEnabled = modulePlayer.renderer.name != "UADE"
    
    // Favourite button
    let faveIcon = ModulePlayer.sharedInstance.currentModule?.favorite == true ? "star.fill" : "star"
    let faveButton = CPNowPlayingImageButton(image: UIImage(systemName: faveIcon)!) { _ in
      RadioInteractor.sharedInstance.toggleFavorite()
      self.updateNowPlayingButtons()
    }

    buttons.append(loopButton)
    buttons.append(faveButton)
    
    CPNowPlayingTemplate.shared.updateNowPlayingButtons(buttons)
  }
}

// MARK: - CPNowPlayingTemplateObserver
extension CPPlayQueueController: CPNowPlayingTemplateObserver {
  func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
    self.showPlayQueue()
  }
}
