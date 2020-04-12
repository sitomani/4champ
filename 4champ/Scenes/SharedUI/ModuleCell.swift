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
  
  @IBAction func faveTapped(_ sender: UIButton) {
    delegate?.faveTapped(cell: self)
  }
  
  @IBAction func saveTapped(_ sender: UIButton) {
    delegate?.saveTapped(cell: self)
  }
}

extension ModuleCell {
  func configure(with module: MMD) {
    nameLabel?.text = module.name!
    composerLabel?.text = module.composer!
    typeLabel?.text = module.type!
    stopImage?.isHidden = module.supported()
    
    if module.hasBeenSaved() || module.supported() == false {
      sizeLabel?.text = "\(module.size!) Kb"
      saveButton?.isHidden = true
    } else {
      saveButton?.isHidden = false
      sizeLabel?.text = "\(module.size!) Kb"
    }
    
    faveButton?.isSelected = module.favorite
    faveButton?.isHidden = !module.supported()
  }
}
