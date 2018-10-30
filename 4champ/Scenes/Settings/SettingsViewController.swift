//
//  SettingsViewController.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SettingsDisplayLogic: class {
  func displaySettings(viewModel: Settings.Update.ValueBag)
}

class SettingsViewController: UITableViewController, SettingsDisplayLogic {
  var interactor: SettingsBusinessLogic?
  var router: (NSObjectProtocol & SettingsRoutingLogic & SettingsDataPassing)?

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  // MARK: Setup
  private func setup() {
    let viewController = self
    let interactor = SettingsInteractor()
    let presenter = SettingsPresenter()
    let router = SettingsRouter()
    viewController.interactor = interactor
    viewController.router = router
    interactor.presenter = presenter
    presenter.viewController = viewController
    router.viewController = viewController
    router.dataStore = interactor
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SettingsView_Title".l13n()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateSettings(fetchOnly: true)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    self.updateSettings(fetchOnly: false)
    super.viewWillDisappear(animated)
  }
  
  // MARK: Do something

  @IBAction func separationValueChanged(_ sender: UISlider) {
    DispatchQueue.main.async {
      self.updateSettings(fetchOnly: false)
    }
  }
  
  func updateSettings(fetchOnly: Bool) {
    var request: Settings.Update.ValueBag?
    if fetchOnly == false {
      request = self.buildValueBag()
    }
    interactor?.updateSettings(request: request)
  }
  
  func displaySettings(viewModel: Settings.Update.ValueBag) {
    if let domainCell = tableView.cellForRow(at: IndexPath.init(row: 0, section: 0)) as? SettingsDomainCell {
      domainCell.domainNameField?.text = viewModel.domainName
    }
    
    if let stereoCell = tableView.cellForRow(at: IndexPath.init(row: 0, section: 1)) as? SettingsStereoCell {
      let textFormat = "Settings_StereoSeparation".l13n()
      stereoCell.title?.text = String.init(format: textFormat, "\(Int(viewModel.stereoSeparation * 100))")
      stereoCell.slider?.value = viewModel.stereoSeparation
    }
  }
  
  private func buildValueBag() -> Settings.Update.ValueBag {
    var valueBag = Settings.Update.ValueBag(domainName: "", stereoSeparation: 0)
    
    if let domainCell = tableView.cellForRow(at: IndexPath.init(row: 0, section: 0)) as? SettingsDomainCell,
      let domainName = domainCell.domainNameField?.text {
      valueBag.domainName = domainName
    }
    
    if let stereoCell = tableView.cellForRow(at: IndexPath.init(row: 0, section: 1)) as? SettingsStereoCell,
      let separation = stereoCell.slider?.value {
      valueBag.stereoSeparation = separation
    }
    
    return valueBag
  }
  
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    view.endEditing(true)
  }
}
