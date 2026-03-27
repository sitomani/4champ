//
//  CurrentPlaylistController.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 15.3.2026.
//

import CarPlay

class CPPlaylistsController: NSObject {
  weak var interfaceController: CPInterfaceController?
  var currentPlaylistId: String?
  var template = CPListTemplate.init(type: .currentPlaylist)
  var listsTemplate = CPListTemplate.init(type: .playlists)
  
  let defaultIcon = UIImage.init(named: "playlist_default")?.withTintColor(.label, renderingMode: .alwaysTemplate)
  let playlistIcon = UIImage.init(named: "playlist")?.withTintColor(.label, renderingMode: .alwaysTemplate)
  
  init(interfaceController: CPInterfaceController) {
    super.init()
    self.interfaceController = interfaceController
    let playButton = CPBarButton.init(image: UIImage.init(systemName: "play.fill")!) {[weak self] _ in
      self?.startPlaylist(shuffleMode: .noShuffle)
    }
    let shuffleButton = CPBarButton.init(image: UIImage.init(systemName: "shuffle")!) {[weak self] _ in
      self?.startPlaylist(shuffleMode: .shuffle)
    }
    template.trailingNavigationBarButtons = [shuffleButton, playButton]
    PlaylistInteractor.sharedInstance.addPresenter(self)
  }
  
  func cleanup() {
    log.debug("")
    PlaylistInteractor.sharedInstance.removePresenter(self)
  }
  
  func showPlaylist(plid: String) {
    log.debug("")
    PlaylistInteractor.sharedInstance.selectPlaylist(request: Playlists.Select.Request(playlistId: plid))
  }
  
  func updatePlaylistsTemplate() {
    log.debug("")
    let lists = PlaylistInteractor.sharedInstance.playlists
    let items: [CPSelectableListItem] = lists.map {
      var icon = playlistIcon
      let id = $0.id ?? "default"
      if id == "default" {
        icon = defaultIcon
      }
      let item: CPSelectableListItem = CPListItem.init(
        text: "\($0.name ?? "noname") (\($0.modules.count))",
        detailText: nil,
        image: icon)
      item.handler = { [weak self] _, completion in
        self?.showPlaylist(plid: id)
        completion()
      }
      
      let player = ModulePlayer.sharedInstance
      if player.currentPlaylistName == $0.name && [.playing, .paused].contains(player.status) {
        (item as? CPListItem)?.isPlaying = true
      } else {
        (item as? CPListItem)?.isPlaying = false
      }
      return item
    }
    
    let sections: [CPListSection] = [CPListSection(items: items, header: "", sectionIndexTitle: nil)]
    listsTemplate.updateSections(sections)
  }
  
  func updateCurrentPlaylistTemplate() {
    log.debug("")
    if let plid = currentPlaylistId, let pl = PlaylistInteractor.sharedInstance.playlists.first(where: { $0.id == plid}) {
      let items: [CPSelectableListItem] = pl.modules.map { mmd in
        let item: CPSelectableListItem = CPListItem.init(
          text: mmd.name,
          detailText: mmd.composer,
          image: UIImage.moduleIcon(for: mmd))
        item.handler = { [weak self] _, completion in
          self?.startPlaylist(shuffleMode: .userPreference, with: mmd)
          completion()
        }
        let player = ModulePlayer.sharedInstance
        if player.currentModule?.id == mmd.id && [.playing, .paused].contains(player.status) {
          (item as? CPListItem)?.isPlaying = true
        } else {
          (item as? CPListItem)?.isPlaying = false
        }
        return item
      }
      let sections: [CPListSection] = [CPListSection(items: items, header: pl.name, sectionIndexTitle: nil)]
      template.updateSections(sections)
    }
  }
  
  func startPlaylist(shuffleMode: Playlists.ShuffleMode, with module: MMD? = nil) {
    log.debug("")
    guard let playlistId = currentPlaylistId else { return }
    let pli = PlaylistInteractor.sharedInstance
    pli.selectPlaylist(request: Playlists.Select.Request(playlistId: playlistId))
    if let mmd = module {
      pli.playModule(request: Playlists.Play.Request(mmd: mmd))
    } else {
      pli.startPlaylist(request: Playlists.Start.Request.init(shuffleMode: shuffleMode))
    }
    interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: self.interfaceController?.completionHandler)
  }
}

extension CPPlaylistsController: PlaylistPresentationLogic {
  var presenterId: String {
    "CarPlay-PlaylistController"
  }
  
  func presentPlaylist(response: Playlists.Select.Response) {
    log.debug("")
    currentPlaylistId = response.selectedPlaylist.plId
    updateCurrentPlaylistTemplate()
    if interfaceController?.templates.contains(template) == false {
      interfaceController?.pushTemplate(template, animated: true, completion: self.interfaceController?.completionHandler)
    }
  }
  
  func presentMetadataChanged(response: Playlists.Select.Response) {
    log.debug("")
    updatePlaylistsTemplate()
    updateCurrentPlaylistTemplate()
  }
  
  func presentModeChange(shuffled: Bool) {
  }
  
}
