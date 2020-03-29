//
//  SearchViewController.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SwiftUI

protocol SearchDisplayLogic: class
{
  func displayResult(viewModel: Search.ViewModel)
  func displayDownloadProgress(viewModel: Search.ProgressResponse.ViewModel)
  func displayBatchProgress(viewModel: Search.BatchDownload.ViewModel)
}

class SearchViewController: UIViewController, SearchDisplayLogic
{
  var interactor: SearchBusinessLogic?
  var router: (NSObjectProtocol & SearchRoutingLogic & SearchDataPassing)?
  
  var searchScopes = [SearchType.composer, SearchType.module, SearchType.group, SearchType.meta]
  
  var shouldDisplaySearchBar: Bool = true
  
  @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint?
  @IBOutlet weak var spinner: UIActivityIndicatorView?
  @IBOutlet weak var progressBar: UIProgressView?
  
  var viewModel: Search.ViewModel?
  private var pagingRequestActive: Bool = false
  private var batchProgressView: UIAlertController?
  
  private let progressMarks = ["◐","◓","◑","◒"]
  private var progressMarkIndex = 0
  private var spinnerTimer: Timer?
  
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
    registerXibs(in: tableView)
    tableView?.rowHeight = UITableView.automaticDimension
    tableView?.dataSource = self
    tableView?.delegate = self
    spinner?.isHidden = true
    progressBar?.isHidden = true
    view.backgroundColor = Appearance.darkBlueColor
    tableView?.backgroundColor = Appearance.ampBgColor
    // Based on the context, either show search bar (root level search) or
    // hide it (subsequent searchs on group/composer)
    if shouldDisplaySearchBar {
      searchBar?.showsScopeBar = false
      searchBar?.delegate = self
      searchBar?.searchTextField.textColor = .white
      searchBar?.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
      searchBar?.setScopeBarButtonTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
      
      searchBar?.scopeButtonTitles = searchScopes.map { $0.l13n() }
    } else {
      searchBar?.removeFromSuperview()
      navigationItem.title = router?.dataStore?.autoListTitle
      spinner?.isHidden = false
      spinner?.startAnimating()
      interactor?.triggerAutoFetchList()
    }
    
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
    self.view.addGestureRecognizer(longPressRecognizer)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if shouldDisplaySearchBar {
      navigationItem.title = "TabBar_Search".l13n()
      let text = searchBar?.text ?? ""
      navigationController?.setNavigationBarHidden(text.count != 0, animated: animated)
    } else {
      navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    self.statusChanged(status: modulePlayer.status)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    if searchBar?.text?.count == 0 {
      navigationController?.setNavigationBarHidden(false, animated: animated)
      searchBar?.showsScopeBar = false
    }
  }
  
  deinit {
    log.verbose("")
    modulePlayer.removePlayerObserver(self)
  }
  
  // MARK: Display Logic
  func displayResult(viewModel: Search.ViewModel) {
    log.debug("")
    pagingRequestActive = false
    if let query = searchBar?.text, shouldDisplaySearchBar, query != viewModel.text {
      log.info("Search request result in after change in query. Canceling display")
      return
    }
    
    if let pi = router?.dataStore?.pagingIndex, pi > 0 {
      log.debug("Appending to model")
      self.viewModel?.composers.append(contentsOf: viewModel.composers)
      self.viewModel?.groups.append(contentsOf: viewModel.groups)
      self.viewModel?.modules.append(contentsOf: viewModel.modules)
    } else {
      self.tableView?.setContentOffset(.zero, animated: false)
      self.viewModel = viewModel
    }
    searchBar?.searching = false
    spinner?.stopAnimating()
    spinner?.isHidden = true
    DispatchQueue.main.async {
      self.tableView?.reloadData()
    }
    
    if viewModel.modules.count > 0 && viewModel.text.count == 0 {
      let dlbutton = UIButton.init(type: .system)
      dlbutton.setImage(UIImage.init(named: "downloadall"), for: .normal)
      dlbutton.layoutMargins = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
      dlbutton.setTitle("\(viewModel.modules.count) ", for: .normal)
      dlbutton.sizeToFit()
      dlbutton.addTarget(self, action: #selector(triggerDownloadAll(_:)), for: .touchUpInside)
      dlbutton.semanticContentAttribute = UIApplication.shared
        .userInterfaceLayoutDirection == .rightToLeft ? .forceLeftToRight : .forceRightToLeft
      navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: dlbutton)
    }
    
  }
  
  func displayDownloadProgress(viewModel: Search.ProgressResponse.ViewModel) {
    if viewModel.progress < 1.0 {
      progressBar?.isHidden = false
      view.bringSubviewToFront(progressBar!)
      progressBar?.progress = viewModel.progress
    } else {
      progressBar?.isHidden = true
    }
  }
  
  func displayBatchProgress(viewModel: Search.BatchDownload.ViewModel) {
    batchProgressView?.message = "(\(viewModel.processed) / \(viewModel.batchSize))"
    if viewModel.complete {
      batchProgressView?.dismiss(animated: true, completion: nil)
      stopBatchSpinner()
      progressBar?.progress = 0
      progressBar?.isHidden = true
    }
  }
  
  @objc private func triggerDownloadAll(_ sender: UIBarButtonItem) {
    guard let vm = viewModel else { return }
    
    // dismiss first just in case
    batchProgressView?.dismiss(animated: false, completion: nil)
    batchProgressView = UIAlertController.init(title: "Search_Downloading".l13n(), message: "()", preferredStyle: .alert)
    batchProgressView?.addAction(UIAlertAction.init(title: "G_Cancel".l13n(), style: .cancel, handler: { _ in
      self.interactor?.cancelDownload()
    }))
    present(batchProgressView!, animated: true, completion: nil)
    startBatchSpinner()
    let modids = vm.modules.map { $0.id! }
    let request = Search.BatchDownload.Request(moduleIds: modids)
    interactor?.downloadModules(request)
  }
  
  @objc func longPressed(sender: UILongPressGestureRecognizer) {
    if sender.state == UIGestureRecognizer.State.began {
      let touchPoint = sender.location(in: self.tableView)
      if let indexPath = tableView?.indexPathForRow(at: touchPoint) {
        print("Long pressed row: \(indexPath.row)")
        if let cell = tableView?.cellForRow(at: indexPath) as? ModuleCell {
          longTap(cell: cell )
        }
      }
    }
  }
  
  private func startBatchSpinner() {
    spinnerTimer?.invalidate()
    spinnerTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { (timer) in
      let nextMark = self.progressMarks[self.progressMarkIndex]
      self.batchProgressView?.title = "Search_Downloading".l13n() + nextMark
      self.progressMarkIndex = (self.progressMarkIndex + 1) % self.progressMarks.count
    })
  }
  
  private func stopBatchSpinner() {
    
  }
}

// MARK: SearchBar Delegate
extension SearchViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    prepareSearch(keyword: searchText)
  }
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.showsScopeBar = true
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    prepareSearch(keyword: searchBar.text ?? "")
  }
  
  private func prepareSearch(keyword: String) {
    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(triggerSearch), object: nil)
    if keyword.count == 0 {
      searchBar?.searching = false
      viewModel = Search.ViewModel(modules: [], composers: [], groups: [], text:"")
      tableView?.reloadData()
    } else {
      searchBar?.searching = true
      perform(#selector(triggerSearch), with: nil, afterDelay: Constants.searchDelay)
    }
  }
  
  @objc private func triggerSearch() {
    log.debug("")
    guard let text = searchBar?.text, text.count > 0 else {
      searchBar?.searching = false
      return
    }
    interactor?.search(Search.Request(text: text, type: searchScopes[searchBar?.selectedScopeButtonIndex ?? 0], pagingIndex: 0))
  }
  
}

// MARK: Datasource
extension SearchViewController: UITableViewDataSource {
  func registerXibs(in tableView: UITableView?) {
    guard let tableView = tableView else { return }
    tableView.register(UINib(nibName: "ModuleCell", bundle: nil), forCellReuseIdentifier: "ModuleCell")
    tableView.register(UINib(nibName: "ComposerCell", bundle: nil), forCellReuseIdentifier: "ComposerCell")
    tableView.register(UINib(nibName: "GroupCell", bundle: nil), forCellReuseIdentifier: "GroupCell")
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel?.numberOfRows() ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let vm = viewModel else { return UITableViewCell() }
    
    let rows = vm.numberOfRows()
    let pagingIndex = router?.dataStore?.pagingIndex ?? 0
    if pagingIndex != rows &&
      pagingRequestActive == false &&
      rows > 30 && indexPath.row > rows - 5 {
      if let text = searchBar?.text {
        pagingRequestActive = true
        let nextPageRequest = Search.Request(text: text, type: searchScopes[searchBar?.selectedScopeButtonIndex ?? 0], pagingIndex: rows)
        interactor?.search(nextPageRequest)
      }
    }
    let cell = vm.dequeueCell(for: tableView, at: indexPath.row)
    if let modCell = (cell as? ModuleCell) {
      modCell.delegate = self
      modCell.faveButton?.isHidden = true
    }
    return cell
  }
}

// MARK: Table view delegate
extension SearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    log.debug("")
    guard let ds = viewModel, indexPath.row < ds.numberOfRows() else { return }
    view.endEditing(true)
    if let cell = tableView.cellForRow(at: indexPath) {
      cell.backgroundColor = Appearance.separatorColor
      UIView.animate(withDuration: 0.3) {
        cell.backgroundColor = UIColor.clear
      }
    }
    if ds.modules.count > 0 {
      guard let id = ds.modules[indexPath.row].id, ds.modules[indexPath.row].supported() else { return }
      interactor?.download(moduleId: id)
    } else if ds.groups.count > 0 {
      let id = ds.groups[indexPath.row].id
      let title = ds.groups[indexPath.row].name
      router?.toComposerList(title: title, groupId: id)
    } else if ds.composers.count > 0 {
      let id = ds.composers[indexPath.row].id
      let title = ds.composers[indexPath.row].name
      router?.toModulesList(title: title, composerId: id)
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    searchBar?.endEditing(true)
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
  
  func errorOccurred(error: PlayerError) {
    //nop at the moment
  }
  
  func queueChanged() {
    // nop
  }
}

// MARK: ViewModel extensions for tableview
extension Search.ViewModel {
  func dequeueCell(for tableView: UITableView, at row: Int) -> UITableViewCell {
    if modules.count > row {
      if let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleCell") as? ModuleCell {
        let module = modules[row]
        cell.nameLabel?.text = module.name!
        cell.composerLabel?.text = module.composer!
        cell.sizeLabel?.text = "\(module.size!) Kb"
        cell.typeLabel?.text = module.type!
        cell.stopImage?.isHidden = module.supported()
        cell.progressVeil?.isHidden = true
        //        if let _ = module.localPath {
        //          cell.progressVeil?.isHidden = true
        //        } else {
        //          cell.progressVeil?.isHidden = false
        //        }
        return cell
      }
    } else if composers.count > row {
      if let cell = tableView.dequeueReusableCell(withIdentifier: "ComposerCell") as? ComposerCell {
        let composer = composers[row]
        cell.nameLabel?.text = composer.name
        cell.realNameLabel?.text = composer.realName
        cell.groupsLabel?.text = composer.groups
        return cell
      }
    } else if groups.count > row {
      if let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell") as? GroupCell {
        let group = groups[row]
        cell.nameLabel?.text = group.name
        return cell
      }
      
    }
    return UITableViewCell()
  }
  
  func numberOfRows() -> Int {
    if modules.count > 0 {
      return modules.count
    } else if composers.count > 0 {
      return composers.count
    } else if groups.count > 0 {
      return groups.count
    }
    return 0
  }
}

extension SearchViewController: ModuleCellDelegate {
  func faveTapped(cell: ModuleCell) {
    guard let ip = tableView?.indexPath(for: cell),
      let module = viewModel?.modules[ip.row] else {
        return
    }
    _ = moduleStorage.toggleFavorite(module: module)
  }
  
  func longTap(cell: ModuleCell) {
    if let ip = tableView?.indexPath(for: cell),
      let mmd = viewModel?.modules[ip.row] {
      router?.toPlaylistSelector(module: mmd)

      
//      let contentView = PlaylistPickerView2(dismissAction: dismissAction, module: mod).environment(\.managedObjectContext, moduleStorage.managedObjectContext)
//      let vc = UIHostingController(rootView: contentView)
//      vc.view.backgroundColor = .clear
//      present(vc, animated: true)
    }
  }
  
  func dismissAction() {
    self.dismiss( animated: true, completion: nil )
  }
  
  func addAction(moduleId: Int, playlistId: String) {
    log.error("addAction")
    // TODO: Add the module to playlist
  }
}
