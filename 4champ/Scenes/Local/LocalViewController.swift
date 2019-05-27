//
//  LocalViewController.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//


import UIKit
import CoreData

protocol LocalDisplayLogic: class
{
  func displaySomething(viewModel: Local.Something.ViewModel)
  func displayPlayerError(message: String)
}

class LocalViewController: UIViewController, LocalDisplayLogic
{
  var interactor: LocalBusinessLogic?
  var router: (NSObjectProtocol & LocalRoutingLogic & LocalDataPassing)?
  
  var ms = ModuleStorage()
  
  @IBOutlet var tableView: UITableView!
  @IBOutlet var tableBottomConstraint: NSLayoutConstraint!
  
  private var searchBar: UISearchBar?
  private var sortKey: LocalSortKey = .module
  
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
    let interactor = LocalInteractor()
    let presenter = LocalPresenter()
    let router = LocalRouter()
    viewController.interactor = interactor
    viewController.router = router
    interactor.presenter = presenter
    presenter.viewController = viewController
    router.viewController = viewController
    router.dataStore = interactor
  }
  
  // MARK: Routing
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    view.endEditing(true)
  }
  
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
  override func viewDidAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    doSomething()
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UINib(nibName: "ModuleCell", bundle: nil), forCellReuseIdentifier: "ModuleCell")
    doSomething()
    modulePlayer.addPlayerObserver(self)
    
    searchBar = UISearchBar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 44))
    self.tableView.tableHeaderView = searchBar
    searchBar?.delegate = self
    
    tableView.backgroundColor = Appearance.ampBgColor
    tableView.contentOffset = CGPoint.init(x: 0, y: 44)
    //    let btn1 = UIBarButtonItem.init(image: UIImage.init(named: "modicon")?.resizeImageWith(newSize: CGSize.init(width: 30, height: 30)), style: .plain, target: nil, action: nil)
    updateBarButtons()
  }
  
  deinit {
    modulePlayer.removePlayerObserver(self)
  }
  
  @objc func handleBarButtonPress(sender: UIBarButtonItem) {
    if let key = LocalSortKey.init(rawValue: sender.tag) {
      log.debug(key)
      sortKey = key
      let req = Local.SortFilter.Request.init(sortKey: sortKey, filterText: searchBar?.text, ascending: false)
      interactor?.sortAndFilter(request:req)
    } else {
      tableView.setContentOffset(CGPoint.zero, animated: true)
    }
    updateBarButtons()
  }
  
  func updateBarButtons() {
    let btn1 = UIBarButtonItem.init(title: "Type", style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn1.tag = LocalSortKey.type.rawValue
    let btn2 = UIBarButtonItem.init(title: "Module", style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn2.tag = LocalSortKey.module.rawValue
    let btn3 = UIBarButtonItem.init(title: "Composer", style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn3.tag = LocalSortKey.composer.rawValue
    let btn4 = UIBarButtonItem.init(title: "Size", style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn4.tag = LocalSortKey.size.rawValue
    let btn5 = UIBarButtonItem.init(image: UIImage.init(named: "favestar-yellow"), style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn5.tag = LocalSortKey.favorite.rawValue
    let btn6 = UIBarButtonItem.init(title: "Filter", style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn6.tag = -1 //No sort key for filter

    _ = [btn1, btn2, btn3, btn4, btn5, btn6].map {
      if $0.tag == sortKey.rawValue {
        $0.tintColor = UIColor.white
        $0.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        $0.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .highlighted)
      } else {
        $0.tintColor = Appearance.barTitleColor
        $0.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Appearance.barTitleColor], for: .normal)
        $0.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Appearance.barTitleColor], for: .highlighted)
      }
    }
    
    self.navigationItem.leftBarButtonItems = [btn1, btn2, btn3]
    self.navigationItem.rightBarButtonItems = [btn6, btn5, btn4]
  }
  
  // MARK: Do something
  
  
  func doSomething()
  {
    let request = Local.Something.Request()
    interactor?.doSomething(request: request)
  }
  
  func displaySomething(viewModel: Local.Something.ViewModel)
  {
    tableView.reloadData()
  }
  
  func displayPlayerError(message: String) {
    let av = UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
    self.present(av, animated: true)
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4.0) {
        av.dismiss(animated: true, completion: nil)
    }
  }
}

extension LocalViewController: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
  }
  
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
    return ""
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    
  }
}

extension LocalViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    view.endEditing(true)
    interactor?.playModule(at: indexPath)
  }
}

extension LocalViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return interactor?.moduleCount() ?? 0
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleCell") as? ModuleCell {
      if let module = interactor?.getModule(at: indexPath) {
        cell.nameLabel?.text = module.name
        cell.composerLabel?.text = module.composer
        cell.typeLabel?.text = module.type
        cell.sizeLabel?.text = "\(module.size ?? 0) Kb"
      }
      return cell
    }
    return UITableViewCell()
  }
}


// MARK: Module Player Observer
extension LocalViewController: ModulePlayerObserver {
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
  
  func errorOccurred(error: PlayerError) {
    //nop at the moment
  }
}

extension LocalViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    let req = Local.SortFilter.Request.init(sortKey: sortKey, filterText: searchText, ascending: false)
    interactor?.sortAndFilter(request: req)
  }
}
