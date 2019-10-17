//
//  RadioViewController.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol RadioDisplayLogic: class
{
  func displayControlStatus(viewModel: Radio.Control.ViewModel)
  func displayChannelBuffer(viewModel: Radio.ChannelBuffer.ViewModel)
  func displayPlaybackTime(viewModel: Radio.Playback.ViewModel)
  func displayLocalNotificationStatus(viewModel: Radio.LocalNotifications.ViewModel)
  func displayNewModules(viewModel: Radio.NewModules.ViewModel)
}

class RadioViewController: UIViewController, RadioDisplayLogic
{
  var interactor: RadioBusinessLogic?
  var router: (NSObjectProtocol & RadioRoutingLogic & RadioDataPassing)?

  @IBOutlet weak var currentModuleView: UIView?
  @IBOutlet weak var channelSegments: UISegmentedControl?
  @IBOutlet weak var downloadProgress: UIProgressView?
  
  @IBOutlet weak var switchTitle: UILabel?
  @IBOutlet weak var nextUpTitle: UILabel?
  
  @IBOutlet weak var nameLabel: UILabel?
  @IBOutlet weak var composerLabel: UILabel?
  @IBOutlet weak var sizeLabel: UILabel?
  @IBOutlet weak var timeLabel: UILabel?
  
  @IBOutlet weak var localLabel: UILabel?
  @IBOutlet weak var saveButton: UIButton?
  @IBOutlet weak var faveButton: UIButton?
  @IBOutlet weak var shareButton: UIButton?
  
  @IBOutlet weak var notifyButton: UIButton?
  @IBOutlet weak var radioSwitch: UISwitch?
  
  // MARK: Object lifecycle
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
  {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
    setup()
  }
  
  // MARK: Setup
  
  private func setup()
  {
    let viewController = self
    let interactor = RadioInteractor()
    let presenter = RadioPresenter()
    let router = RadioRouter()
    viewController.interactor = interactor
    viewController.router = router
    interactor.presenter = presenter
    presenter.viewController = viewController
    router.viewController = viewController
    router.dataStore = interactor
    interactor.refreshBadge()
  }
  
  // MARK: Routing
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?)
  {
    if let scene = segue.identifier {
      let selector = NSSelectorFromString("routeTo\(scene)WithSegue:")
      if let router = router, router.responds(to: selector) {
        router.perform(selector, with: segue)
      }
    }
  }
  
  // MARK: View lifecycle
  
  override func viewDidLoad()
  {
    log.debug("")
    super.viewDidLoad()
    
    self.view.backgroundColor = Appearance.ampBgColor
    
    UIUtils.roundCornersInView(currentModuleView)
    navigationItem.title = "RadioView_Title".l13n().uppercased()

    localLabel?.isHidden = true
    shareButton?.isHidden = true
    faveButton?.isHidden = false
    saveButton?.isHidden = true
    notifyButton?.isHidden = true

    channelSegments?.setTitle("Radio_All".l13n(), forSegmentAt: 0)
    channelSegments?.setTitle("Radio_New".l13n(), forSegmentAt: 1)
    channelSegments?.setTitle("Radio_Local".l13n(), forSegmentAt: 2)
    
    channelSegments?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
    channelSegments?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)

    interactor?.refreshLocalNotificationsStatus()
    interactor?.refreshBadge()
    displayChannelBuffer(viewModel: Radio.ChannelBuffer.ViewModel(nowPlaying: nil, nextUp: nil))
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  // MARK: Do something
  func displayControlStatus(viewModel: Radio.Control.ViewModel) {
    switch viewModel.status {
    case .on:
      switchTitle?.text = "Radio_StatusOn".l13n()
    case .off:
      switchTitle?.text = "Radio_StatusOff".l13n()
      nextUpTitle?.text = ""
      switchTitle?.textColor = UIColor.white
      radioSwitch?.onTintColor = Appearance.successColor
    case .noModulesAvailable:
        fallthrough
    case .failure:
      switchTitle?.text = "Radio_FetchFailed".l13n()
      switchTitle?.textColor = Appearance.errorColor
      radioSwitch?.onTintColor = Appearance.errorColor
    case .fetching(let progress):
      nextUpTitle?.text = "Radio_Fetching".l13n()
      downloadProgress?.progress = progress
      downloadProgress?.setNeedsDisplay()
    }
  }
  
  func displayChannelBuffer(viewModel: Radio.ChannelBuffer.ViewModel) {
    log.debug("")
    if let nextUp = viewModel.nextUp {
      nextUpTitle?.text = nextUp
    } else {
      nextUpTitle?.text = ""
    }
    
    if let current = viewModel.nowPlaying {
      currentModuleView?.alpha = 1
      composerLabel?.text = current.composer ?? ""
      nameLabel?.text = current.name ?? ""
      sizeLabel?.text = "\(current.size ?? 0) kb"
      localLabel?.isHidden = !current.hasBeenSaved()
      faveButton?.isSelected = current.favorite
    } else {
      currentModuleView?.alpha = 0.8
      downloadProgress?.progress = 0
      localLabel?.isHidden = true
      composerLabel?.text = "Radio_StatusOff".l13n()
      nameLabel?.text = "..."
      sizeLabel?.text = "0 kb"
      faveButton?.isSelected = false
    }
  }
  
  func displayPlaybackTime(viewModel: Radio.Playback.ViewModel) {
    timeLabel?.text = viewModel.timeLeft
  }
  
  func displayLocalNotificationStatus(viewModel: Radio.LocalNotifications.ViewModel) {
    log.debug("")
    notifyButton?.setTitle(viewModel.buttonTitle, for: .normal)
    notifyButton?.isHidden = false
  }

  func displayNewModules(viewModel: Radio.NewModules.ViewModel) {
    log.debug("")
    
    if let text = viewModel.badgeText {
      navigationController?.tabBarItem.badgeValue = viewModel.badgeText
      let fmt = "Radio_New_Count".l13n()
      let title = String.init(format: fmt, text)
      channelSegments?.setTitle(title, forSegmentAt: 1)
    } else {
      channelSegments?.setTitle("Radio_New".l13n(), forSegmentAt: 1)
      navigationController?.tabBarItem.badgeValue = nil
    }
  }
  
  @IBAction private func ntfButtonTapped(_ sender: UIButton) {
    interactor?.requestLocalNotifications()
  }
  
  @IBAction private func nextTapped(_ sender: UIButton) {
    interactor?.playNext()
  }
  
  @IBAction private func controlSwitchChanged(_ sender: UISwitch) {
    log.debug("")
    if let channelSelection = RadioChannel(rawValue: channelSegments?.selectedSegmentIndex ?? 0) {
      let req = Radio.Control.Request(powerOn: sender.isOn, channel: channelSelection)
      interactor?.controlRadio(request: req)
    }
  }
  
  @IBAction private func faveTapped(_ sender: UIButton) {
    interactor?.toggleFavorite()
  }
  
  @IBAction private func segmentChanged(_ sender: UISegmentedControl) {
    log.debug("")
    if let channelSelection = RadioChannel(rawValue: sender.selectedSegmentIndex ) {
      let req = Radio.Control.Request(powerOn: radioSwitch?.isOn ?? false, channel: channelSelection)
      interactor?.controlRadio(request: req)
    }
  }
}
