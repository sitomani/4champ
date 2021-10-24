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
  func displaySessionHistoryInsert()
}

class RadioViewController: UIViewController, RadioDisplayLogic
{
  var interactor: RadioBusinessLogic?
  var router: (NSObjectProtocol & RadioRoutingLogic & RadioDataPassing)?

  private var currentModule: MMD?
  
  @IBOutlet weak var currentModuleView: UIView?
  @IBOutlet weak var channelSegments: UISegmentedControl?
  @IBOutlet weak var downloadProgress: UIProgressView?
  
  @IBOutlet weak var switchTitle: UILabel?
  @IBOutlet weak var nextUpTitle: UILabel?
  @IBOutlet weak var historyTitle: UILabel?
  
  @IBOutlet weak var nameLabel: UILabel?
  @IBOutlet weak var composerLabel: UILabel?
  @IBOutlet weak var sizeLabel: UILabel?
  @IBOutlet weak var timeLabel: UILabel?
  
  @IBOutlet weak var localLabel: UILabel?
  @IBOutlet weak var saveButton: UIButton?
  @IBOutlet weak var faveButton: UIButton?
  @IBOutlet weak var shareButton: UIButton?
  
  @IBOutlet weak var radioSwitch: UISwitch?
  @IBOutlet weak var prevButton: UIButton?
  @IBOutlet weak var nextButton: UIButton?
  
  @IBOutlet weak var radioTable: UITableView?
  @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint?

  var notifyItem: UIBarButtonItem?
  
  private let gradientLayer = CAGradientLayer()
  let gradientColorTop =  UIColor.init(rgb: 0x16538a)
  let gradientColorBottom = UIColor.init(rgb: 0x16538a)
  
  enum GradientAnimationDirection: String {
    case none
    case `in` = "colorIn"
    case out = "colorOut"
  }
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
//    saveButton?.isHidden = true


    channelSegments?.setTitle("Radio_All".l13n(), forSegmentAt: 0)
    channelSegments?.setTitle("Radio_New".l13n(), forSegmentAt: 1)
    channelSegments?.setTitle("Radio_Local".l13n(), forSegmentAt: 2)
    
    channelSegments?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
    channelSegments?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
    downloadProgress?.trackTintColor = UIColor.white.withAlphaComponent(0.1)
    
    interactor?.refreshLocalNotificationsStatus()
    interactor?.refreshBadge()
    displayChannelBuffer(viewModel: Radio.ChannelBuffer.ViewModel(nowPlaying: nil, nextUp: nil, historyAvailable: false))
    
    radioTable?.dataSource = self
    radioTable?.delegate = self
    radioTable?.separatorStyle = .none
    radioTable?.register(RadioSessionCell.self, forCellReuseIdentifier: RadioSessionCell.ReuseId)

    setupGradientBackground()
    
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
    currentModuleView?.addGestureRecognizer(longPressRecognizer)
    
    let img = UIImage(named: "notifications-add")?.withRenderingMode(.alwaysTemplate)
    notifyItem = UIBarButtonItem.init(image: img, landscapeImagePhone: img, style: .plain, target: self, action: #selector(notificationsPressed))
    self.navigationItem.rightBarButtonItem = notifyItem
  }
  
  @objc func longPressed(sender: UILongPressGestureRecognizer) {
    if sender.state == UIGestureRecognizer.State.began {
      if let mod = currentModule {
        router?.toPlaylistSelector(module: mod)
      }
    }
  }
  
  @objc func notificationsPressed(sender: UINavigationItem) {
    interactor?.requestLocalNotifications()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  

  func setupGradientBackground() {
      gradientLayer.colors = [gradientColorTop.withAlphaComponent(0).cgColor, gradientColorBottom.withAlphaComponent(0).cgColor]
      gradientLayer.locations = [0.0, 1.0]
      gradientLayer.drawsAsynchronously = true
      gradientLayer.frame = CGRect.init(x: 0, y: 0, width: view.frame.width, height: currentModuleView?.frame.height ?? 100)
      currentModuleView?.layer.insertSublayer(gradientLayer, at:0)
  }
  
  func animateGradient(_ direction: GradientAnimationDirection) {
    guard gradientLayer.animation(forKey: direction.rawValue) == nil else { return }
    gradientLayer.removeAnimation(forKey: GradientAnimationDirection.in.rawValue)
    gradientLayer.removeAnimation(forKey: GradientAnimationDirection.out.rawValue)

    let startAlphas: [CGFloat] = direction == .in ? [0, 0] : [1,0.2]
    gradientLayer.colors = [gradientColorTop.withAlphaComponent(startAlphas[0]).cgColor, gradientColorBottom.withAlphaComponent(startAlphas[1]).cgColor]

    let gradientChangeAnimation = CABasicAnimation(keyPath: "colors")
    gradientChangeAnimation.duration = 0.5
    
    let endAlphas: [CGFloat] = direction == .in ? [1, 0.2] : [0,0]

    gradientChangeAnimation.toValue = [
      gradientColorTop.withAlphaComponent(endAlphas[0]).cgColor,
      gradientColorBottom.withAlphaComponent(endAlphas[1]).cgColor
    ]
    gradientChangeAnimation.fillMode = CAMediaTimingFillMode.forwards
    gradientChangeAnimation.isRemovedOnCompletion = false
    gradientLayer.add(gradientChangeAnimation, forKey: direction.rawValue)
  }
 
  
  
  func displayControlStatus(viewModel: Radio.Control.ViewModel) {
    switch viewModel.status {
    case .on:
      switchTitle?.text = "Radio_StatusOn".l13n()
      switchTitle?.textColor = UIColor.white
      radioSwitch?.onTintColor = Appearance.successColor
      radioSwitch?.isOn = true
    case .off:
      switchTitle?.text = "Radio_StatusOff".l13n()
      nextUpTitle?.text = ""
      switchTitle?.textColor = UIColor.white
      radioSwitch?.onTintColor = Appearance.successColor
      radioSwitch?.isOn = false
    case .noModulesAvailable:
      switchTitle?.text = "Radio_NoLocalModules".l13n()
      switchTitle?.textColor = Appearance.errorColor
      radioSwitch?.onTintColor = Appearance.errorColor
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
      nextUpTitle?.text = radioSwitch?.isOn ?? false ? " " : "" // just to keep the space open when radio is on
    }
    
    prevButton?.isEnabled = viewModel.historyAvailable
    nextButton?.isEnabled = viewModel.nowPlaying != nil
    
    if let current = viewModel.nowPlaying {
      currentModule = current
      currentModuleView?.alpha = 1
      composerLabel?.text = current.composer
      nameLabel?.text = current.name ?? ""
      sizeLabel?.text = "\(current.size ?? 0) kb"
      localLabel?.isHidden = !current.hasBeenSaved()
      faveButton?.isSelected = current.favorite
      saveButton?.isHidden = current.hasBeenSaved()
      // For now, hide the share button (sharing through the long-tap menu)
      shareButton?.isHidden = true
      animateGradient(.in)
      tableBottomConstraint?.constant = 50.0
    } else {
      currentModule = nil
      currentModuleView?.alpha = 0.8
      downloadProgress?.progress = 0
      localLabel?.isHidden = true
      composerLabel?.text = "Radio_StatusOff".l13n()
      nameLabel?.text = "..."
      sizeLabel?.text = "0 kb"
      faveButton?.isSelected = false
      saveButton?.isHidden = false
      shareButton?.isHidden = true
      tableBottomConstraint?.constant = 0
      radioTable?.reloadData()
      animateGradient(.out)
      historyTitle?.text = ""
    }
  }
  
  func displayPlaybackTime(viewModel: Radio.Playback.ViewModel) {
    timeLabel?.text = viewModel.timeLeft
  }
  
  func displayLocalNotificationStatus(viewModel: Radio.LocalNotifications.ViewModel) {
    log.debug("")
    notifyItem?.image = UIImage(named: viewModel.imageName)
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
  
  func displaySessionHistoryInsert() {
    historyTitle?.text = "Previous:"
    radioTable?.insertRows(at: [IndexPath.init(item: 0, section: 0)], with: .top)
  }
  
  @IBAction private func saveTapped(_ sender: UIButton) {
    interactor?.saveCurrentModule()
  }
  
  @IBAction private func shareTapped(_ sender: UIButton) {
    interactor?.shareCurrentModule()
  }
  
  @IBAction private func nextTapped(_ sender: UIButton) {
    interactor?.playNext()
  }
  
  @IBAction private func prevTapped(_ sender: UIButton) {
    interactor?.playPrev();
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

extension RadioViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return interactor?.getSessionLength() ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: RadioSessionCell.ReuseId) as? RadioSessionCell, let mod = interactor?.getModule(at: indexPath) {
      let modName = mod.name ?? "n/a"
      let composer = mod.composer ?? "n/a"
      
      cell.moduleTitle.text = "\(modName.trimmingCharacters(in: .whitespaces)) by \(composer)"
      return cell
    } else {
      return UITableViewCell()
    }
  }
  
  func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    log.debug("foo")
    return indexPath
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    interactor?.playFromSessionHistory(at: indexPath)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 40
  }
}

