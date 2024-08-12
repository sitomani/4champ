//
//  SearchViewController.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SwiftUI

protocol SearchDisplayLogic: class {
  func displayResult(viewModel: Search.ViewModel)
  func displayDownloadProgress(viewModel: Search.ProgressResponse.ViewModel)
  func displayBatchProgress(viewModel: Search.BatchDownload.ViewModel)
  func displayMetaDataChange(viewModel: Search.MetaDataChange.ViewModel)
  func displayDeletion(viewModel: Search.MetaDataChange.ViewModel)
}

extension SearchViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

class SearchViewController: UIViewController, SearchDisplayLogic {
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

  private let progressMarks = ["◐", "◓", "◑", "◒"]
  private var progressMarkIndex = 0
  private var spinnerTimer: Timer?

  private lazy var radioButtonLPR: UILongPressGestureRecognizer = UILongPressGestureRecognizer(
    target: self,
    action: #selector(radioButtonLongPressed(sender:)))

  @IBOutlet weak var searchBar: UISearchBar?

  @IBOutlet weak var tableView: UITableView?
  @IBOutlet weak var searchBarToEdgeConstraint: NSLayoutConstraint?
  @IBOutlet weak var radioButton: UIButton?

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
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
      if let tf = searchBar?.searchTextField {
        tf.leftView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        tf.leftView?.tintColor = .lightGray
      }

      searchBar?.scopeButtonTitles = searchScopes.map { $0.l13n() }
    } else {
      searchBar?.removeFromSuperview()
      navigationItem.title = router?.dataStore?.autoListTitle?.uppercased()
      spinner?.isHidden = false
      spinner?.startAnimating()
      interactor?.triggerAutoFetchList()
    }
    animateRadioButton(false)
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
    self.view.addGestureRecognizer(longPressRecognizer)

    radioButton?.addGestureRecognizer(radioButtonLPR)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if shouldDisplaySearchBar {
      navigationItem.title = "TabBar_Search".l13n().uppercased()
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
      self.animateRadioButton()
    }
    updateDownloadAllButton()
  }

  func animateRadioButton(_ animated: Bool = true) {
    var modules: [MMD] = []
    if searchBar?.superview != nil {
      modules = viewModel?.modules ?? []
    }
    var targetAlpha = 1.0
    var targetConstant = 48.0
    let animTime = animated ? 0.3 : 0
    self.searchBarToEdgeConstraint?.priority = .required

    if modules.isEmpty {
      targetAlpha = 0.0
      targetConstant = 0
    }
    UIView.animate(withDuration: animTime) {
      self.radioButton?.alpha = targetAlpha
      self.searchBarToEdgeConstraint?.constant = targetConstant
    }

  }

  func updateDownloadAllButton() {
    guard let vm = self.viewModel else {
      return
    }

    if vm.modules.count > 0 && vm.text.count == 0 {
      var onlineOnly = vm.modules.count
      for mod in vm.modules {
        if mod.hasBeenSaved() || mod.supported() == false {
          onlineOnly -= 1
        }
      }

      let dlbutton = UIButton.init(type: .system)
      dlbutton.setImage(UIImage.init(named: "downloadall"), for: .normal)
      dlbutton.layoutMargins = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
      dlbutton.setTitle("\(onlineOnly)", for: .normal)
      dlbutton.sizeToFit()
      dlbutton.addTarget(self, action: #selector(triggerDownloadAll(_:)), for: .touchUpInside)
      dlbutton.semanticContentAttribute = UIApplication.shared
        .userInterfaceLayoutDirection == .rightToLeft ? .forceLeftToRight : .forceRightToLeft

      let radioButton = UIButton(type: .system)
      radioButton.setImage(UIImage(named: "radio"), for: .normal)
      radioButton.addTarget(self, action: #selector(startArtistRadio(_:)), for: .touchUpInside)
      radioButton.addGestureRecognizer(radioButtonLPR)

      var navItems: [UIBarButtonItem] = []
      if vm.modules.count > 0 {
        navItems.append(UIBarButtonItem(customView: radioButton))
      }
      if onlineOnly > 0 {
        navItems.append(UIBarButtonItem(customView: dlbutton))
      }
      navigationItem.rightBarButtonItems = navItems
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
    if let err = viewModel.error {
      if let ip = tableView?.indexPathForSelectedRow,
        let cell = tableView?.cellForRow(at: ip) as? ModuleCell {
        cell.showMessageOverlay(message: err)
      }
    }
  }

  func displayBatchProgress(viewModel: Search.BatchDownload.ViewModel) {
    batchProgressView?.message = "(\(viewModel.processed) / \(viewModel.batchSize))"
    if viewModel.complete {
      batchProgressView?.dismiss(animated: true, completion: nil)
      stopBatchSpinner()
      progressBar?.progress = 0
      progressBar?.isHidden = true
      tableView?.reloadData()
    }
    updateDownloadAllButton()
  }

  func displayMetaDataChange(viewModel: Search.MetaDataChange.ViewModel) {
    self.viewModel?.updateModule(module: viewModel.module)
    if let modIndex = self.viewModel?.modules.index(of: viewModel.module),
       nil != tableView?.window {
      tableView?.reloadRows(at: [IndexPath(row: modIndex, section: 0)], with: .fade)
    } else {
      tableView?.reloadData()
    }
  }

  func displayDeletion(viewModel: Search.MetaDataChange.ViewModel) {
    self.viewModel?.updateModule(module: viewModel.module)
    if let modIndex = self.viewModel?.modules.index(of: viewModel.module), nil != tableView?.window {
      tableView?.reloadRows(at: [IndexPath(row: modIndex, section: 0)], with: .left)
    } else {
      tableView?.reloadData()
    }
    updateDownloadAllButton()
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

  @objc private func startArtistRadio(_: UIBarButtonItem) {
    interactor?.startCustomChannel(selection: nil, appending: false)
  }

  @IBAction func startResultsRadio(_: UIButton) {
    let mods = viewModel?.modules ?? []
    let selection = Radio.CustomSelection(name: viewModel?.text ?? "n/a", ids: mods.map { $0.id ?? 0 }.shuffled())
    interactor?.startCustomChannel(selection: selection, appending: false)
  }

  @objc func longPressed(sender: UILongPressGestureRecognizer) {
    if sender.state == UIGestureRecognizer.State.began {
      let touchPoint = sender.location(in: self.tableView)
      if let indexPath = tableView?.indexPathForRow(at: touchPoint) {
        log.debug("Long pressed row: \(indexPath.row)")
        if let cell = tableView?.cellForRow(at: indexPath) as? ModuleCell {
          longTap(cell: cell )
        }
      }
    }
  }

  @objc func radioButtonLongPressed(sender: UILongPressGestureRecognizer) {
    if sender.state == .began {
      let mods = viewModel?.modules ?? []
      let selection = Radio.CustomSelection(name: viewModel?.text ?? "n/a", ids: mods.map { $0.id ?? 0 }.shuffled())
      interactor?.startCustomChannel(selection: selection, appending: true)
    }
  }

  private func startBatchSpinner() {
    spinnerTimer?.invalidate()
    spinnerTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { (_) in
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
      viewModel = Search.ViewModel(modules: [], composers: [], groups: [], text: "")
      tableView?.reloadData()
      animateRadioButton()
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
//      modCell.faveButton?.isHidden = true
    }
    return cell
  }

  func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    guard (viewModel?.modules.count ?? 0) > 0 else {
      return nil
    }
    return "SearchView_Remove".l13n()
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    guard let modules = viewModel?.modules, modules.count > indexPath.row else {
      return .none
    }
    if modules[indexPath.row].hasBeenSaved() {
      return .delete
    } else {
      return .none
    }
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    guard (viewModel?.modules.count ?? 0) > 0 else {
      return
    }

    if editingStyle == .delete {
      interactor?.deleteModule(at: indexPath)
    }
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
  func moduleChanged(module: MMD, previous: MMD?) {
    tableView?.reloadData()
  }

  func statusChanged(status: PlayerStatus) {
    DispatchQueue.main.async {
      self.doHandleStatusChange(status: status)
    }
  }

  func doHandleStatusChange(status: PlayerStatus) {
    if status == .stopped || status == .initialised {
      tableBottomConstraint?.constant = 0
    } else {
      tableBottomConstraint?.constant = 50.0
    }
    tableView?.reloadData()
  }

  func errorOccurred(error: PlayerError) {
    let vm = Search.ProgressResponse.ViewModel(progress: 0, error: "Error_PlaybackFailed".l13n())
    displayDownloadProgress(viewModel: vm)
  }

  func queueChanged(changeType: QueueChange) {
    // nop
  }
}

// MARK: ViewModel extensions for tableview
extension Search.ViewModel {
  func dequeueCell(for tableView: UITableView, at row: Int) -> UITableViewCell {
    if modules.count > row {
      if let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleCell") as? ModuleCell {
        let module = modules[row]
        cell.configure(with: module)
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

  mutating func updateModule(module: MMD) {
    if let index = self.modules.firstIndex(where: { (mmd) -> Bool in
      mmd.id == module.id
    }) {
      modules[index] = module
    }
  }
}

extension SearchViewController: ModuleCellDelegate {
  func faveTapped(cell: ModuleCell) {
    guard let ip = tableView?.indexPath(for: cell),
      let module = viewModel?.modules[ip.row], let modId = module.id, module.supported() else {
        return
    }

    if module.hasBeenSaved() {
      _ = moduleStorage.toggleFavorite(module: module)
    } else {
      let request = Search.BatchDownload.Request(moduleIds: [modId], favorite: true)
      interactor?.downloadModules(request)
    }
  }

  func saveTapped(cell: ModuleCell) {
    guard let ip = tableView?.indexPath(for: cell),
      let module = viewModel?.modules[ip.row], let modId = module.id, module.supported() else {
        return
    }
    let request = Search.BatchDownload.Request(moduleIds: [modId])
    interactor?.downloadModules(request)
  }

  func shareTapped(cell: ModuleCell) {
    guard let ip = tableView?.indexPath(for: cell),
          let module = viewModel?.modules[ip.row],
          module.id != nil,
          module.supported() else {
        return
    }
    shareUtil.shareMod(mod: module)
  }

  func longTap(cell: ModuleCell) {
    if let ip = tableView?.indexPath(for: cell),
      let mmd = viewModel?.modules[ip.row] {
      router?.toPlaylistSelector(module: mmd)
    }
  }

  func dismissAction() {
    self.dismiss( animated: true, completion: nil )
  }

  func addAction(moduleId: Int, playlistId: String) {
    log.error("not expecting addAction")
  }
}
