//
//  SearchViewController.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SearchDisplayLogic: class
{
  func displaySomething(viewModel: Search.ModuleQuery.ViewModel)
}

class SearchViewController: UIViewController, SearchDisplayLogic
{
  var interactor: SearchBusinessLogic?
  var router: (NSObjectProtocol & SearchRoutingLogic & SearchDataPassing)?
  
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
    doSomething()
  }
  
  deinit {
    modulePlayer.removePlayerObserver(self)
  }
  // MARK: Do something
  
  //@IBOutlet weak var nameTextField: UITextField!
  
  func doSomething()
  {
//    let request = Search.ModuleQuery.Request()
//    interactor?.doSomething(request: request)
  }
  
  func displaySomething(viewModel: Search.ModuleQuery.ViewModel)
  {
    //nameTextField.text = viewModel.name
  }
}

// Mark datasource testing
extension SearchViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return modulePlayer.playlist.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleCell") as? ModuleCell {
      let module = modulePlayer.playlist[indexPath.row]
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

extension SearchViewController: ModulePlayerObserver {
  func moduleChanged(module: MMD) {
    tableView?.reloadData()
  }
  func statusChanged(status: PlayerStatus) {
    tableView?.reloadData()
  }
}
