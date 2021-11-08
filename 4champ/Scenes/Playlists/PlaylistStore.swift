//
//  PlaylistStore.swift
//  4champ
//
//  Created by Aleksi Sitomaniemi on 15.3.2020.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import SwiftUI

protocol PlaylistDisplayLogic: class
{
  func displayPlaylist(viewModel: Playlists.Select.ViewModel)
  func displayModeChange(shuffled: Bool)
}

class PlaylistStore: ObservableObject, PlaylistDisplayLogic
{
  var interactor: PlaylistBusinessLogic?
  var router: (NSObjectProtocol & PlaylistRoutingLogic & PlaylistDataPassing)?
  weak var hostingController: UIHostingController<PlaylistView>?
  // MARK: Object lifecycle

  @Published var viewModel: Playlists.Select.ViewModel
  @Published var nowPlaying: Bool
  
  // MARK: Setup
  
  init() {
    viewModel = Playlists.Select.ViewModel(playlistName: "", shuffle: false, modules: [])
    nowPlaying = false
    modulePlayer.addPlayerObserver(self)
    moduleStorage.addStorageObserver(self)
  }
  
  init(viewModel: Playlists.Select.ViewModel) {
    nowPlaying = false
    self.viewModel = viewModel
  }
  
  deinit {
    modulePlayer.removePlayerObserver(self)
    moduleStorage.removeStorageObserver(self)
  }
  
  func setup()
  {
    let viewController = self
    let interactor = PlaylistInteractor()
    let presenter = PlaylistPresenter()
    let router = PlaylistRouter()
    viewController.interactor = interactor
    viewController.router = router
    interactor.presenter = presenter
    presenter.viewController = viewController
    router.dataStore = interactor
    interactor.selectPlaylist(request: Playlists.Select.Request(playlistId: ""))
  }
  
  func displayPlaylist(viewModel: Playlists.Select.ViewModel) {
    self.viewModel = viewModel
  }
  
  func displayModeChange(shuffled: Bool) {
    self.viewModel.shuffle = shuffled
  }
}

extension PlaylistStore: ModulePlayerObserver {
  func moduleChanged(module: MMD, previous: MMD?) {
    hostingController?.rootView.navigationButtonID = UUID()
  }
  
  func statusChanged(status: PlayerStatus) {
    if status == .stopped || status == .initialised {
      nowPlaying = false
    } else {
      nowPlaying = true
    }
  }
  
  func errorOccurred(error: PlayerError) {
    //nop at the moment
  }
  
  func queueChanged(changeType: QueueChange) {
    //nop
  }
}

extension PlaylistStore: ModuleStorageObserver {
  func metadataChange(_ mmd: MMD) {
    //nop
  }
  
  func playlistChange() {
    let req = Playlists.Select.Request(playlistId: moduleStorage.currentPlaylist?.plId ?? "default")
    interactor?.selectPlaylist(request: req)
  }
}
