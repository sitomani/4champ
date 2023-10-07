//
//  AboutViewController.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol AboutDisplayLogic: class {
  func displayNowPlaying(_ viewModel: About.Status.ViewModel)
}

class AboutViewController: UIViewController, AboutDisplayLogic {
  var interactor: AboutBusinessLogic?
  var router: (NSObjectProtocol & AboutRoutingLogic & AboutDataPassing)?

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var bottomAnchor: NSLayoutConstraint?

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
    let interactor = AboutInteractor()
    let presenter = AboutPresenter()
    let router = AboutRouter()
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
    log.debug("")
    super.viewDidLoad()
    self.view.backgroundColor = Appearance.ampBgColor

    tabBarItem.title = "TabBar_About".l13n()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.sectionHeaderHeight = 60
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 360
    UIUtils.roundCornersInView(tableView)
    navigationItem.title = "AboutView_Title".l13n().uppercased()

    toggleNowPlaying(modulePlayer.status.rawValue > PlayerStatus.stopped.rawValue)

    let img = UIImage(named: "favestar-grey")?.withRenderingMode(.alwaysTemplate)
    let buttonItem = UIBarButtonItem.init(image: img, landscapeImagePhone: img, style: .plain, target: self, action: #selector(reviewNow))
    self.navigationItem.leftBarButtonItem = buttonItem
  }

  // MARK: Display Logic
  func displayNowPlaying(_ viewModel: About.Status.ViewModel) {
    // TODO
  }

  @objc func reviewNow() {
    ReviewActions.giveReview()
  }
}

extension AboutViewController: NowPlayingContainer {
  func toggleNowPlaying(_ value: Bool) {
    log.debug("")
      if value {
        bottomAnchor?.constant = -(50.0 + 10.0)
      } else {
        bottomAnchor?.constant = -10.0
    }
    view.layoutIfNeeded()
  }
}

extension AboutViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    guard let titles = interactor?.details.titles else { return 0 }
    return titles.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let contentKeys = interactor?.details.contents else { return 0 }
    if section < contentKeys.count {
      return 1
    } else {
      return interactor?.details.licenseNames.count ?? 0
    }
  }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && indexPath.section == 1 {
            let twitterUrl = URL(string: "https://twitter.com/4champ_app")!
            UIApplication.shared.open(twitterUrl)
        }
    }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    guard let contentKeys = interactor?.details.contents else { return cell }

    let text: String
    if indexPath.section < contentKeys.count {
      text = contentKeys[indexPath.section].l13n()
    } else {
      guard let licNames = interactor?.details.licenseNames, licNames.count > indexPath.row else { return cell }
      text = licNames[indexPath.row]
      cell.accessoryType = .detailButton
    }
    cell.textLabel?.textAlignment = .center
    cell.textLabel?.numberOfLines = 0
    cell.textLabel?.text = text
    cell.textLabel?.textColor = .white
    cell.backgroundColor = .clear
    cell.selectionStyle = .none
    return cell
  }
}

extension AboutViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let titles = interactor?.details.titles,
      let images = interactor?.details.images,
      section < titles.count && section < images.count else { return UIView() }

    return AboutHeaderView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: 40), titleKey: titles[section], imageKey: images[section])
  }

  func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    guard indexPath.row < interactor?.details.licenseLinks.count ?? 0 else { return }

    if let licUrls = interactor?.details.licenseLinks {
        let urlString = licUrls[indexPath.row]
        if let targetUrl = URL.init(string: urlString) {
            UIApplication.shared.open(targetUrl)
        } else {
            let ac = UIAlertController.init(title: "About_Licenses".l13n(), message: urlString, preferredStyle: .alert)
            ac.addAction(UIAlertAction.init(title: "G_OK".l13n(), style: .default, handler: nil))
            present(ac, animated: false)
        }
    }
  }
}
