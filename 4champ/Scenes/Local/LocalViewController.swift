//
//  LocalViewController.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import CoreData
import SwiftUI

protocol LocalDisplayLogic: class {
  func displayModules(viewModel: Local.SortFilter.ViewModel)
  func displayPlayerError(message: String)
  func displayRowDeletion(indexPath: IndexPath)
  func displayRowUpdate(indexPath: IndexPath)
  func displayRowInsert(indexPath: IndexPath)
}

class LocalViewController: UIViewController, LocalDisplayLogic {
  var interactor: LocalBusinessLogic?
  var router: (NSObjectProtocol & LocalRoutingLogic & LocalDataPassing)?
  
  @IBOutlet var tableView: UITableView!
  @IBOutlet var tableBottomConstraint: NSLayoutConstraint!
  @IBOutlet var noModulesLabel: UILabel!
  
  private var searchBar: UISearchBar?
  private var sortKey: LocalSortKey = .module
  
  // MARK: Object lifecycle
  
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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UINib(nibName: "ModuleCell", bundle: nil), forCellReuseIdentifier: "ModuleCell")
    modulePlayer.addPlayerObserver(self)
    prepareView()
    
    searchBar = UISearchBar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 44))
    searchBar?.searchTextField.textColor = .white
    if let tf = searchBar?.searchTextField {
      tf.leftView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
      tf.leftView?.tintColor = .lightGray
    }
    self.tableView.tableHeaderView = searchBar
    searchBar?.delegate = self
    
    tableView.backgroundColor = Appearance.ampBgColor
    tableView.contentOffset = CGPoint.init(x: 0, y: 44)
    //    let btn1 = UIBarButtonItem.init(image: UIImage.init(named: "modicon")?.resizeImageWith(newSize: CGSize.init(width: 30, height: 30)), style: .plain, target: nil, action: nil)
    updateBarButtons()
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 76
    
    noModulesLabel.text = "ModulesView_NoModules".l13n()
    
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
    self.view.addGestureRecognizer(longPressRecognizer)
  }
  
  deinit {
    modulePlayer.removePlayerObserver(self)
  }
  
  @objc func longPressed(sender: UILongPressGestureRecognizer) {
    if sender.state == UIGestureRecognizer.State.began {
      let touchPoint = sender.location(in: self.tableView)
      if let indexPath = tableView.indexPathForRow(at: touchPoint) {
        log.debug("Long pressed row: \(indexPath.row)")
        if let cell = tableView.cellForRow(at: indexPath) as? ModuleCell {
          longTap(cell: cell )
        }
      }
    }
  }
  
  @objc func handleBarButtonPress(sender: UIBarButtonItem) {
    if let key = LocalSortKey.init(rawValue: sender.tag) {
      log.debug(key)
      sortKey = key
      let req = Local.SortFilter.Request.init(sortKey: sortKey, filterText: searchBar?.text, ascending: false)
      interactor?.sortAndFilter(request: req)
    } else if let op = SpecialFunctions.init(rawValue: sender.tag) {
      switch op {
      case .filter:
        tableView.setContentOffset(CGPoint.zero, animated: false)
      case .import:
        interactor?.importModules()
      }
    }
    updateBarButtons()
  }
  
  func updateBarButtons() {
    let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light, scale: .large)
    let importImage = UIImage.init(systemName: "square.and.arrow.down", withConfiguration: config)
    let addBtn = UIBarButtonItem.init(image: importImage, style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    addBtn.tag = -2 // no sort key for import button
    let btn1 = UIBarButtonItem.init(title: "ModuleInfo_Type".l13n(), style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn1.tag = LocalSortKey.type.rawValue
    let btn2 = UIBarButtonItem.init(title: "G_Module".l13n(), style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn2.tag = LocalSortKey.module.rawValue
    let btn3 = UIBarButtonItem.init(title: "ModuleInfo_Handle".l13n(), style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn3.tag = LocalSortKey.composer.rawValue
    let btn4 = UIBarButtonItem.init(title: "ModuleInfo_Size".l13n(), style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn4.tag = LocalSortKey.size.rawValue
    let btn5 = UIBarButtonItem.init(image: UIImage.init(named: "favestar-yellow"), style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn5.tag = LocalSortKey.favorite.rawValue
    let btn6 = UIBarButtonItem.init(title: "ModulesView_Filter".l13n(), style: .plain, target: self, action: #selector(handleBarButtonPress(sender:)))
    btn6.tag = -1 // No sort key for filter
    
    _ = [addBtn, btn1, btn2, btn3, btn4, btn5, btn6].map {
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
    
    self.navigationItem.leftBarButtonItems = [addBtn, btn1, btn2, btn3]
    self.navigationItem.rightBarButtonItems = [btn6, btn5, btn4]
  }
  
  // MARK: Do something
  func prepareView() {
    let request = Local.SortFilter.Request(sortKey: .module, filterText: nil, ascending: true)
    interactor?.sortAndFilter(request: request)
  }
  
  func displayModules(viewModel: Local.SortFilter.ViewModel) {
    tableView.reloadData()
  }
  
  func displayPlayerError(message: String) {
    let av = UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
    self.present(av, animated: true)
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4.0) {
      av.dismiss(animated: true, completion: nil)
    }
  }
  
  func displayRowDeletion(indexPath: IndexPath) {
    tableView.deleteRows(at: [indexPath], with: .fade)
  }
  
  func displayRowUpdate(indexPath: IndexPath) {
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }
  
  func displayRowInsert(indexPath: IndexPath) {
    tableView.insertRows(at: [indexPath], with: .automatic)
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
    let count = interactor?.moduleCount() ?? 0
    if count == 0 {
      if (searchBar?.text?.count ?? 0) == 0 {
        noModulesLabel.isHidden = false
      }
    } else {
      noModulesLabel.isHidden = true
    }
    return count
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleCell") as? ModuleCell {
      if let module = interactor?.getModule(at: indexPath) {
        cell.configure(with: module)
        cell.delegate = self
      }
      return cell
    }
    return UITableViewCell()
  }
  
  func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    return "ModulesView_Delete".l13n()
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      interactor?.deleteModule(at: indexPath)
    }
  }
}

// MARK: Module Player Observer
extension LocalViewController: ModulePlayerObserver {
  func moduleChanged(module: MMD, previous: MMD?) {
    //    tableView?.reloadData()
  }
  
  func statusChanged(status: PlayerStatus) {
    if status == .stopped || status == .initialised {
      tableBottomConstraint?.constant = 0
    } else {
      tableBottomConstraint?.constant = 50.0
    }
    tableView?.reloadData()
  }

  func doHandleStatusChange(_ status: PlayerStatus) {

  }
  
  func errorOccurred(error: PlayerError) {
    // nop at the moment
  }
  
  func queueChanged(changeType: QueueChange) {
  }
}

extension LocalViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    let req = Local.SortFilter.Request.init(sortKey: sortKey, filterText: searchText, ascending: false)
    interactor?.sortAndFilter(request: req)
  }
}

// MARK: ModuleCellDelegate
extension LocalViewController: ModuleCellDelegate {
  func faveTapped(cell: ModuleCell) {
    guard let ip = tableView.indexPath(for: cell) else {
      return
    }
    interactor?.toggleFavorite(at: ip)
  }
  
  func saveTapped(cell: ModuleCell) {
    
  }
  
  func shareTapped(cell: ModuleCell) {
    guard let ip = tableView.indexPath(for: cell),
      let mod = interactor?.getModule(at: ip) else {
        return
    }
    shareUtil.shareMod(mod: mod)
  }
  
  func longTap(cell: ModuleCell) {
    
    guard let ip = tableView.indexPath(for: cell),
      let mod = interactor?.getModule(at: ip) else {
        return
    }
    router?.toPlaylistSelector(module: mod)
  }
}
