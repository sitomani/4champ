//
//  VisualizerViewController.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SpriteKit

struct ViewElement {
  static let None      : UInt32 = 0
  static let All       : UInt32 = UInt32.max
  static let Text      : UInt32 = 0b1       // 1
  static let Visualiser: UInt32 = 0b10      // 2
}

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
  @IBOutlet weak var separator:UIView!
  
  @IBOutlet weak var textButton:UIButton!
  @IBOutlet weak var vizButton:UIButton!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var vizView:SKView!
  
  var hasUpdatedVisibility:Bool = false
  
  private var playbackTimer: Timer?
  
  @IBAction func handleGesture(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .began:
      if (sender.velocity(in: self.view).y) > 0 {
        self.presentingViewController?.dismiss(animated: true, completion: nil);
      }
      break;
    default:
      var v = 0;
      v = v+1;
      //nop
    }
  }
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    //Fixing issue with launching app on iOS8
    super.init(nibName: nibNameOrNil ?? "NowPlayingViewController", bundle: nibBundleOrNil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  @IBAction func dismissMe (_ sender:UIButton) {
    log.debug("")
    modulePlayer.removePlayerObserver(self)
    playbackTimer?.invalidate()
    self.presentingViewController?.dismiss(animated: true, completion:nil)
  }
  
  @IBAction func prev (_ sender:UIButton) {
    modulePlayer.playPrev()
  }
  
  @IBAction func next (_ sender:UIButton) {
    modulePlayer.playNext()
  }
  
  @IBAction func togglePlay (_ sender:UIButton) {
    if modulePlayer.status == .playing {
      modulePlayer.pause()
    } else {
      modulePlayer.resume()
    }
    sender.isSelected = modulePlayer.status == .paused
  }
  
  @IBAction func toggleText(_:UIButton) {
    log.debug("")
    textButton.isSelected = !textButton.isSelected
    UserDefaults.standard.set(textButton.isSelected, forKey: "nowplaying_text")
    updateVisibility(ViewElement.Text)
  }
  
  func updateVisibility(_ element:UInt32) {
    let textHidden = UserDefaults.standard.bool(forKey: "nowplaying_text")
    let vizHidden = UserDefaults.standard.bool(forKey: "nowplaying_viz")
    
    //Update button selected status (to have right status when view is loaded)
    textButton?.isSelected = textHidden
    vizButton?.isSelected = vizHidden
    
    if (element & ViewElement.Text > 0) {
      if (textHidden) {
        fadeOut(scrollV!){}
      } else {
        fadeIn(scrollV!){}
      }
    }
    
    if (element & ViewElement.Visualiser > 0) {
      if (vizHidden) {
        stopVisualisation()
      } else {
        startVisualisation()
      }
    }
  }
  
  func fadeIn(_ view:UIView, completion:@escaping ()->Void) {
    if (view.isHidden) {
      view.alpha = 0
    }
    view.isHidden = false
    UIView.animate(withDuration: 0.3, animations: {
      view.alpha = 1
    }, completion: { (_) in
      completion()
    })
  }
  
  func fadeOut(_ view:UIView, completion:@escaping ()->Void) {
    UIView.animate(withDuration: 0.3, animations: {
      view.alpha = 0
    }, completion: { (_) in
      view.isHidden = true
      completion()
    })
  }
  
  
  @IBAction func toggleVisualiser(_:UIButton) {
    log.debug("")
    vizButton?.isSelected = !vizButton!.isSelected
    UserDefaults.standard.set(vizButton!.isSelected, forKey: "nowplaying_viz")
    updateVisibility(ViewElement.Visualiser)
  }
  
  @IBAction func share (_ sender:UIButton) {
  }
  
  deinit {
    modulePlayer.removePlayerObserver(self)
  }
  
  func periodicUpdate() {
    let length = modulePlayer.renderer.moduleLength()
    let pos = modulePlayer.renderer.currentPosition()
    self.playhead?.maximumValue = Float(length)
    self.playhead?.value = Float(pos)
    let timeLeft = pos;
    let seconds = timeLeft % 60
    let minutes = (timeLeft - seconds) / 60
    let txt = String(format:"%d:%02d", minutes, seconds)
    self.playhead?.updatePlayhead(txt)
  }
  
  func updateView(module: MMD?) {
    log.debug("")
    if let sv = self.scrollV {
      sv.contentOffset = CGPoint(x: 0,y: 0);
    }
    guard let info = module else { return }

    startPlaybackTimer()
    
    titleLabel.text = info.name! + " (" + info.type! + ")"
    sizeLabel.text = "\(info.size!) Kb"
    
    let playlistName = modulePlayer.radioOn ? " | Radio" : ""
    composerLabel.text = info.composer! + playlistName
    faveStar.isSelected = info.favorite

    var samples:Array<String>
    samples = modulePlayer.renderer.getInstruments()
    if (samples.count == 0) {
      samples = modulePlayer.renderer.getSamples()
    }
    
    var str:String
    str = ""
    for sampleName in samples {
      str.append(sampleName)
      str.append("\n")
    }
    self.samplesLabel?.text = str
    if (hasUpdatedVisibility) {
      updateVisibility(ViewElement.All)
    }
  }
  
  @IBAction func toggleFavorite() {
    guard let mod = modulePlayer.currentModule,
          let updated = moduleStorage.toggleFavorite(module: mod) else {
            return
    }
    updateFaveStar(updated.favorite)
  }
  
  
  @IBAction func sliderChanged() {
    modulePlayer.renderer.setCurrentPosition(Int32(self.playhead!.value))
  }
  
  @IBAction func saveTapped() {
  }
  
  func animateColLabel(_ visible:Bool) {
    let alpha:Float = visible ? 0.5 : 0
    UIView.animate(withDuration: 0.3, animations: {
      self.collectionLabel?.alpha = CGFloat(alpha)
    })
  }
  
  func updateFaveStar(_ favorited:Bool) {
    if (favorited) {
      self.saveButton?.isHidden = true;
      animateColLabel(true);
      self.faveStar.isSelected = true
    } else {
      self.faveStar.isSelected = false
    }
  }
  
  func shareComplete() {
    self.updateShareStatus(true);
  }
  
  func updateShareStatus(_ shared:Bool) {
    if (shared) {
      self.shareButton?.setImage(UIImage.init(named: "shareicon_done.png"), for: UIControl.State())
    } else {
      self.shareButton?.setImage(UIImage.init(named: "shareicon.png"), for: UIControl.State())
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopVisualisation()
  }
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
  
  override func viewDidLoad() {
    log.debug("")
    super.viewDidLoad()
    modulePlayer.addPlayerObserver(self)
    
    scrollV.delegate = self
    scrollV.backgroundColor = UIColor.clear
    
    //Hide UI elements that are currently not supported
    collectionLabel.text = NSLocalizedString("Radio_InLocalCollection", comment: "")
    collectionLabel.isHidden = true
    saveButton.isHidden = true
    faveStar.isHidden = false
    shareButton.isHidden = true

    updateView(module: modulePlayer.currentModule)
    if modulePlayer.status == .playing {
      startPlaybackTimer()
    }
    playButton.isSelected = modulePlayer.status == .paused
  }
  
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if (scrollView.contentOffset.y < -60) {
      self.presentingViewController?.dismiss(animated: true, completion: nil);
    }
    scrollView.contentOffset.x = 0;
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if (!hasUpdatedVisibility) {
      hasUpdatedVisibility = true
      updateVisibility(ViewElement.All)
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  func startVisualisation() {
    log.debug("")
    let view = self.vizView
    fadeIn(view!){}
    
    let vizHidden = UserDefaults.standard.bool(forKey: "nowplaying_viz")
    view?.isHidden = vizHidden
    
    view?.presentScene(nil) //to make sure to release anything previously presented
    view?.backgroundColor = UIColor(red:0.07, green:0.20, blue:0.34, alpha:1.0)
    let scene:SKScene = AmpVizScene(size: view!.bounds.size)
    view?.presentScene(scene)
  }
  
  func stopVisualisation() {
    log.debug("")
    fadeOut(vizView) {self.vizView.presentScene(nil)}
  }
}

extension VisualizerViewController: ModulePlayerObserver {
  func moduleChanged(module: MMD) {
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
      if modulePlayer.playlist.count == 0 {
        DispatchQueue.main.async {
          self.dismissMe(self.vizButton!)
        }
      }
    }
  }
    
  func errorOccurred(error: PlayerError) {
    //nop at the moment
  }
  
  func playlistChanged() {
    //nop at the moment
  }
  
  func startPlaybackTimer() {
    playbackTimer?.invalidate()
    playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.periodicUpdate()
    }
  }
}
