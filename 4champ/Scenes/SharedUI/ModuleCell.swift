//
//  ModuleCell.swift
//  ampplayer
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol ModuleCellDelegate: class {
  func faveTapped(cell: ModuleCell)
  func saveTapped(cell: ModuleCell)
  func shareTapped(cell: ModuleCell)
  func longTap(cell: ModuleCell)
}

/**
 TableView cell representing a module
 */
class ModuleCell: UITableViewCell {
  weak var delegate: ModuleCellDelegate?

  @IBOutlet weak var nameLabel: UILabel?
  @IBOutlet weak var composerLabel: UILabel?
  @IBOutlet weak var sizeLabel: UILabel?
  @IBOutlet weak var typeLabel: UILabel?
  @IBOutlet weak var faveButton: UIButton?
  @IBOutlet weak var stopImage: UIImageView?
  @IBOutlet weak var saveButton: UIButton?
  @IBOutlet weak var shareButton: UIButton?

  @IBAction func faveTapped(_ sender: UIButton) {
    delegate?.faveTapped(cell: self)
  }

  @IBAction func saveTapped(_ sender: UIButton) {
    delegate?.saveTapped(cell: self)
  }

  @IBAction func shareTapped(_ sender: UIButton) {
    delegate?.shareTapped(cell: self)
  }
}

extension ModuleCell {
  func configure(with module: MMD) {
    nameLabel?.text = module.name
    composerLabel?.text = (module.composer?.trimmingCharacters(in: .whitespaces).count ?? 0) > 0 ? module.composer : " "
    typeLabel?.text = module.type!
    stopImage?.isHidden = module.supported()

    if module.hasBeenSaved() || module.supported() == false {
      sizeLabel?.text = "\(module.size!) Kb"
      saveButton?.isHidden = true
    } else {
      saveButton?.isHidden = false
      sizeLabel?.text = "\(module.size!) Kb"
    }

    // For now, hide the share button (sharing through the long-tap menu)
    shareButton?.isHidden = true

    faveButton?.isSelected = module.favorite
    faveButton?.isHidden = !module.supported()
  }

  func showMessageOverlay(message: String) {
    let lbl = UILabel.init(frame: self.contentView.frame)
    lbl.backgroundColor = Appearance.errorColor
    lbl.text = message
    lbl.textColor = UIColor.white
    lbl.font = UIFont.systemFont(ofSize: 20.0)
    lbl.numberOfLines = 0
    lbl.alpha = 0.8
    lbl.textAlignment = .center
    self.contentView.addSubview(lbl)
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+3.0) {
      UIView.animate(withDuration: 1.0, animations: {lbl.alpha=0}, completion: {_ in lbl.removeFromSuperview()})
    }
  }
}
