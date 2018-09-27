//
//  SearchViewController.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SearchDisplayLogic: class
{
  func displayModules(viewModel: Search.ViewModel)
}

class SearchViewController: UIViewController, SearchDisplayLogic
{
  var interactor: SearchBusinessLogic?
  var router: (NSObjectProtocol & SearchRoutingLogic & SearchDataPassing)?

  var searchScopes = [SearchType.module, SearchType.composer, SearchType.group, SearchType.meta]

  @IBOutlet var tableBottomConstraint: NSLayoutConstraint?
  
  var viewModel: Search.ViewModel?
  
  @IBOutlet weak var searchBar: UISearchBar?
  
  @IBOutlet weak var tableView: UITableView?
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
    let interactor = SearchInteractor()
    let presenter = SearchPresenter()
    let router = SearchRouter()
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
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    modulePlayer.addPlayerObserver(self)
    tableView?.dataSource = self
    tableView?.delegate = self
    searchBar?.delegate = self
    
    searchBar?.scopeButtonTitles = [SearchType.module.l13n(), SearchType.composer.l13n(), SearchType.group.l13n(), SearchType.meta.l13n()]
  }
  
  deinit {
    modulePlayer.removePlayerObserver(self)
  }
  
  // MARK: Display Logic
  func displayModules(viewModel: Search.ViewModel) {
    self.viewModel = viewModel
    tableView?.reloadData()
  }
}

// MARK: SearchBar Delegate
extension SearchViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(triggerSearch), object: nil)
    perform(#selector(triggerSearch), with: nil, afterDelay: 0.3)
  }
  
  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(triggerSearch), object: nil)
    perform(#selector(triggerSearch), with: nil, afterDelay: 0.3)
  }
  
  @objc func triggerSearch() {
    guard let text = searchBar?.text, text.count > 0 else { return }
    interactor?.search(keyword: text, type: searchScopes[searchBar?.selectedScopeButtonIndex ?? 0])
  }
}

// MARK: Datasource
extension SearchViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let ds = viewModel?.modules else { return 0 }
    return ds.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let ds = viewModel?.modules else { return UITableViewCell() }
    if let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleCell") as? ModuleCell {
      let module = ds[indexPath.row]
      cell.nameLabel?.text = module.name!
      cell.composerLabel?.text = module.composer!
      cell.sizeLabel?.text = "\(module.size!) Kb"
      cell.typeLabel?.text = module.type!
      return cell
    } else {
      return UITableViewCell()
    }
  }
}

// MARK: Table view delegate
extension SearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let ds = viewModel, indexPath.row < ds.modules.count, let id = ds.modules[indexPath.row].id else { return }
    interactor?.download(moduleId: id)
  }
}

// MARK: Module Player Observer
extension SearchViewController: ModulePlayerObserver {
  func moduleChanged(module: MMD) {
    tableView?.reloadData()
  }
  
  func statusChanged(status: PlayerStatus) {
    if status == .stopped || status == .initialised {
      tableBottomConstraint?.constant = 0
    } else {
      tableBottomConstraint?.constant = 50.0
    }
    tableView?.reloadData()
  }
}
