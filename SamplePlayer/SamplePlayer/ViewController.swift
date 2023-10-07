//
//  ViewController.swift
//  SamplePlayer
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var modLabel: UILabel!
  @IBOutlet weak var modStack: UIStackView!
  @IBOutlet weak var viewTitle: UILabel!

  private var modulesUrl: URL?
  private var modulePaths: [String] = []

  let replay = Replay()

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    if let url = Bundle.main.url(forResource: "Modules", withExtension: "bundle") {
      modulesUrl = url
      do {
        modulePaths = try FileManager.default.contentsOfDirectory(atPath: url.path)
      } catch {
        print(error)
      }
    }
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    if let url = Bundle.main.url(forResource: "Modules", withExtension: "bundle") {
      modulesUrl = url
      do {
        modulePaths = try FileManager.default.contentsOfDirectory(atPath: url.path)
      } catch {
        print(error)
      }
    }
    super.init(coder: coder)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    modLabel.textColor = .black
    viewTitle.textColor = .black

  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    replay.initAudio()

    modStack.spacing = 8.0
    modStack.distribution = .fillEqually

    let bundle = Bundle.main // init(identifier: "lib.uade.ios")
    viewTitle.text = bundle.resourcePath ?? ""
//    NSString *bd = [uadeBundle pathForResource:@"UADERes" ofType:@"bundle"];

    // Add module buttons
    modulePaths.forEach { path in
      let btn = UIButton()
      btn.backgroundColor = UIColor.init(red: 0, green: 0x42/255, blue: 0x47/255, alpha: 1)
      let ext = path.split(separator: ".").last
      btn.setTitle(String(ext ?? "n/a").uppercased(), for: .normal)
      btn.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
      modStack.addArrangedSubview(btn)
    }

  }

  @IBAction func buttonTapped(_ sender: UIButton) {
    if let btn = sender.titleLabel?.text {
      switch btn {
      case "STOP":
        modLabel.text = "no module selected"
        replay.stop()
      default:
        if let rootUrl = modulesUrl, let mod = modulePaths.first(where: { path in
          path.uppercased().hasSuffix(btn)
        }) {
          let fullpath = "\(rootUrl.path)/\(mod)"
          modLabel.text = String(mod.split(separator: "/").last ?? "")
          replay.loadModule(fullpath, type: btn)
          replay.play()
        }
      }
    }
  }
}
