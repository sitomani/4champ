//
//  VisualizerViewController.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SpriteKit
import SwiftUI

enum ViewElement: UInt32 {
  case none =         0
  case all =          0b11111111
  case initialised =  0b1
  case text =         0b10
  case channelBars =  0b100
  case amplitude =    0b1000
}

let visIcons: [ViewElement: UIImage?] = [.none: UIImage.init(named: "vizbars_disabled"),
                                         .channelBars: UIImage.init(named: "vizbars"),
                                         .amplitude: UIImage.init(named: "vizgraph")]

class VisualizerViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var composerLabel: UILabel!
  @IBOutlet weak var samplesLabel: UILabel!
  @IBOutlet weak var faveStar: UIButton!
  @IBOutlet weak var shareButton: UIButton!
  @IBOutlet weak var scrollV: UIScrollView!
  @IBOutlet weak var playhead: AmpSlider!
  @IBOutlet weak var sizeLabel: UILabel!
  @IBOutlet weak var saveButton: UIButton!
  @IBOutlet weak var collectionLabel: UILabel!
  @IBOutlet weak var separator: UIView!

  @IBOutlet weak var textButton: UIButton!
  @IBOutlet weak var vizButton: UIButton!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var vizView: SKView!
  @IBOutlet weak var renderView: VertexShaderView!
  @IBOutlet weak var backdrop: UIView!
  @IBOutlet weak var loopButton: UIButton!

  @IBOutlet weak var playerView: UIView!

  var hasUpdatedVisibility: Bool = false

  private var visibilityFlags: UInt32 {
    get {
      let value = UserDefaults.standard.integer(forKey: "nowplaying_elements")
      if value == 0 {
        // uninitialised flags: return the default flags
        return ViewElement.text.rawValue | ViewElement.channelBars.rawValue | ViewElement.initialised.rawValue
      }
      return UInt32(value)
    }
    set {
      UserDefaults.standard.setValue(newValue, forKey: "nowplaying_elements")
    }
  }

  private var playbackTimer: Timer?

  @IBAction func handleGesture(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .began:
      if (sender.velocity(in: self.view).y) > 0 {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
      }
    default: ()
    }
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    // Fixing issue with launching app on iOS8
    super.init(nibName: nibNameOrNil ?? "NowPlayingViewController", bundle: nibBundleOrNil)
 }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  @IBAction func dismissMe (_ sender: UIButton) {
    log.debug("")
    modulePlayer.removePlayerObserver(self)
    playbackTimer?.invalidate()
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }

  @IBAction func prev (_ sender: UIButton) {
    modulePlayer.playPrev()
  }

  @IBAction func next (_ sender: UIButton) {
    modulePlayer.playNext()
  }

  @IBAction func togglePlay (_ sender: UIButton) {
    if modulePlayer.status == .playing {
      modulePlayer.pause()
    } else {
      modulePlayer.resume()
    }
    sender.isSelected = modulePlayer.status == .paused
  }

  @IBAction func toggleText(_: UIButton) {
    log.debug("")
    visibilityFlags ^= ViewElement.text.rawValue
    updateVisibility(ViewElement.text.rawValue)
  }

  func updateVisibility(_ element: UInt32) {
    // Update button selected status (to have right status when view is loaded)
    textButton?.isSelected = visibilityFlags & ViewElement.text.rawValue == 0

    if element & ViewElement.text.rawValue > 0 {
      if visibilityFlags & ViewElement.text.rawValue == 0 {
        fadeOut(scrollV!) {}
      } else {
        fadeIn(scrollV!) {}
      }
    }

    if element & ViewElement.channelBars.rawValue > 0 {
      if visibilityFlags & ViewElement.channelBars.rawValue == 0 {
        stopVisualisation()
      } else {
        startVisualisation()
      }
    }

    if element & ViewElement.amplitude.rawValue > 0 {
      if visibilityFlags & ViewElement.amplitude.rawValue == 0 {
        stopGraph()
      } else {
        startGraph()
      }
    }
  }

  func fadeIn(_ view: UIView, completion: @escaping () -> Void) {
    if view.isHidden {
      view.alpha = 0
    }
    view.isHidden = false
    UIView.animate(withDuration: 0.3, animations: {
      view.alpha = 1
    }, completion: { (_) in
      completion()
    })
  }

  func fadeOut(_ view: UIView, completion: @escaping () -> Void) {
    UIView.animate(withDuration: 0.3, animations: {
      view.alpha = 0
    }, completion: { (_) in
      view.isHidden = true
      completion()
    })
  }

  @IBAction func toggleVisualiser(_: UIButton) {
    log.debug("")
    showVisMenu()
  }

  @IBAction func share (_ sender: UIButton) {
  }

  deinit {
    modulePlayer.removePlayerObserver(self)
  }

  func periodicUpdate() {
    let length = modulePlayer.renderer.moduleLength()
    let pos = modulePlayer.renderer.currentPosition()
    self.playhead?.maximumValue = Float(length)
    self.playhead?.value = Float(pos)
    let timeLeft = pos
    let seconds = timeLeft % 60
    let minutes = (timeLeft - seconds) / 60
    let loop =  pos > length && length > 0 // for UADE tunes length == 0, no looping support
    let txt = String(format: "%d:%02d", minutes, seconds)

    self.playhead?.updatePlayhead(txt, loop: loop)
  }

  func updateView(module: MMD?) {
    log.debug("")
    if let sv = self.scrollV {
      sv.contentOffset = CGPoint(x: 0, y: 0)
    }
    guard let info = module else { return }

    startPlaybackTimer()

    titleLabel.text = info.name + " (" + info.type! + ")"
    sizeLabel.text = "\(info.size!) Kb"

    let playlistName = modulePlayer.radioOn ? " | Radio" : ""
    composerLabel.text = info.composer! + playlistName
    faveStar.isSelected = info.favorite
    loopButton.isSelected = info.loop > 0
    loopButton.isEnabled = modulePlayer.renderer.name != "UADE"
    saveButton.isHidden = info.hasBeenSaved()
    shareButton.isHidden = true

    var samples: [String]
    samples = modulePlayer.renderer.getInstruments()
    if samples.count == 0 {
      samples = modulePlayer.renderer.getSamples()
    }

    var str: String
    str = ""
    for sampleName in samples {
      str.append(sampleName)
      str.append("\n")
    }
    self.samplesLabel?.text = str
    if hasUpdatedVisibility {
      updateVisibility(ViewElement.all.rawValue)
    }
  }

  @IBAction func toggleFavorite() {
    guard let mod = modulePlayer.currentModule,
          let updated = moduleStorage.toggleFavorite(module: mod) else {
            return
    }
    updateFaveStar(updated.favorite)
  }

  @IBAction func toggleLoop (_ sender: UIButton) {
    guard let mod = modulePlayer.currentModule else {
      return
    }
    _ = moduleStorage.toggleLoop(module: mod)
  }

  @IBAction func sliderChanged() {
    modulePlayer.renderer.setCurrentPosition(Int32(self.playhead!.value))
  }

  @IBAction func saveTapped() {
    guard let mod = modulePlayer.currentModule else {
      return
    }
    moduleStorage.addModule(module: mod)
    saveButton.isHidden = true
    shareButton.isHidden = false
  }

  @IBAction func shareTapped() {
    guard let mod = modulePlayer.currentModule else {
      return
    }
    shareUtil.shareMod(mod: mod, presentingVC: self)
  }

  func animateColLabel(_ visible: Bool) {
    let alpha: Float = visible ? 0.5 : 0
    UIView.animate(withDuration: 0.3, animations: {
      self.collectionLabel?.alpha = CGFloat(alpha)
    })
  }

  func updateFaveStar(_ favorited: Bool) {
    if favorited {
      self.saveButton?.isHidden = true
      animateColLabel(true)
      self.faveStar.isSelected = true
    } else {
      self.faveStar.isSelected = false
    }
  }

  func shareComplete() {
    self.updateShareStatus(true)
  }

  func updateShareStatus(_ shared: Bool) {
    if shared {
      self.shareButton?.setImage(UIImage.init(named: "shareicon_done.png"), for: UIControl.State())
    } else {
      self.shareButton?.setImage(UIImage.init(named: "shareicon.png"), for: UIControl.State())
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopVisualisation()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }

  override func viewDidLoad() {
    log.debug("")
    super.viewDidLoad()
    modulePlayer.addPlayerObserver(self)

    scrollV.delegate = self
    scrollV.backgroundColor = UIColor.clear

    // Hide UI elements that are currently not supported
    collectionLabel.text = NSLocalizedString("Radio_InLocalCollection", comment: "")
    collectionLabel.isHidden = true
    saveButton.isHidden = false
    faveStar.isHidden = false
    shareButton.isHidden = true
    backdrop.backgroundColor = UIColor.init(rgb: 0x123357)
    setupVisualisationIcon()
    updateView(module: modulePlayer.currentModule)
    if modulePlayer.status == .playing {
      startPlaybackTimer()
    }
    playButton.isSelected = modulePlayer.status == .paused

    let lpr = UILongPressGestureRecognizer(target: self, action: #selector(showPlaylistPicker(_:)))
    playerView?.addGestureRecognizer(lpr)
  }

  func setupVisualisationIcon() {
    let visElement: ViewElement
    if visibilityFlags & ViewElement.amplitude.rawValue > 0 {
      visElement = .amplitude
    } else if visibilityFlags & ViewElement.channelBars.rawValue > 0 {
      visElement = .channelBars
    } else {
      visElement = .none
    }
    if let img = visIcons[visElement] {
      self.vizButton?.setImage(img, for: .normal)
    }
  }

  @objc func showPlaylistPicker(_ sender: UIGestureRecognizer) {
    guard sender.state == UIGestureRecognizer.State.began, let mmd = modulePlayer.currentModule else {
      return
    }

    let hvc = PlaylistSelectorStore.buildPicker(module: mmd)
    present(hvc, animated: true, completion: nil)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y < -60 {
      self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    scrollView.contentOffset.x = 0
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if !hasUpdatedVisibility {
      hasUpdatedVisibility = true
      updateVisibility(ViewElement.all.rawValue)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  func startVisualisation() {
    log.debug("")
    let view = self.vizView
    fadeIn(view!) {}

    let vizHidden = visibilityFlags & ViewElement.channelBars.rawValue == 0
    view?.isHidden = vizHidden

    view?.presentScene(nil) // to make sure to release anything previously presented
    view?.backgroundColor = UIColor(red: 0.07, green: 0.20, blue: 0.34, alpha: 1.0)
    let scene: SKScene = AmpVizScene(size: view!.bounds.size)
    view?.presentScene(scene)
    view?.isPaused = false
  }

  func stopVisualisation() {
    log.debug("")
    fadeOut(vizView) {
      self.vizView.presentScene(nil)
      self.vizView.isPaused = true
    }
  }

  func startGraph() {
    log.debug("")
    let view = self.renderView
    fadeIn(view!) {}
    let graphHidden = visibilityFlags & ViewElement.amplitude.rawValue == 0
    view?.isHidden = graphHidden
    modulePlayer.streamVisualiser = view
    view?.isPaused = false
  }

  func stopGraph() {
    log.debug("")
    fadeOut(renderView!) {
      modulePlayer.streamVisualiser = nil
      self.renderView?.isPaused = true
    }
  }
}

extension VisualizerViewController: ModulePlayerObserver {
  func moduleChanged(module: MMD, previous: MMD?) {
    log.debug("")
    DispatchQueue.main.async {
      self.updateView(module: module)
    }
  }

  func statusChanged(status: PlayerStatus) {
    log.debug("")
    playButton.isSelected = status == .paused
    if status == .playing {
      startPlaybackTimer()
    }
    if status == .stopped {
      if modulePlayer.playQueue.count == 0 {
        DispatchQueue.main.async {
          self.dismissMe(self.vizButton!)
        }
      }
    }
  }

  func errorOccurred(error: PlayerError) {
    // nop at the moment
  }

  func queueChanged(changeType: QueueChange) {
    // nop at the moment
  }

  func startPlaybackTimer() {
    playbackTimer?.invalidate()
    playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.periodicUpdate()
    }
  }

  func showVisMenu() {
    let popoverContent = UIHostingController(rootView: VisualisationMenu(onButtonPress: { element in
      switch element {
      case .amplitude:
        self.visibilityFlags |= element.rawValue
        self.visibilityFlags &= ~ViewElement.channelBars.rawValue
      case .channelBars:
        self.visibilityFlags |= element.rawValue
        self.visibilityFlags &= ~ViewElement.amplitude.rawValue
      default:
        self.visibilityFlags &= ~ViewElement.amplitude.rawValue
        self.visibilityFlags &= ~ViewElement.channelBars.rawValue
      }
      if let img = visIcons[element] {
        self.vizButton?.setImage(img, for: .normal)
      }

      self.updateVisibility(ViewElement.all.rawValue)
      self.dismiss(animated: true)
    }))
    popoverContent.modalPresentationStyle = .popover
    popoverContent.preferredContentSize = CGSize(width: 120, height: 54)
    if let popoverPresentationController = popoverContent.popoverPresentationController {
        popoverPresentationController.delegate = self
        popoverPresentationController.sourceView = self.vizButton
      popoverPresentationController.sourceRect = CGRect(x: self.vizButton.bounds.midX, y: 0, width: 0, height: self.vizButton.bounds.height)
        popoverPresentationController.permittedArrowDirections = .up
    }
    self.present(popoverContent, animated: true, completion: nil)
  }
}

extension VisualizerViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return .none to ensure that popovers are not adapted to a different style on iPhone
        return .none
    }
}
