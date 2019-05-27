//
//  ModuleCell.swift
//  ampplayer
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol ModuleCellDelegate: class {
    func saveTapped(cell: ModuleCell)
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
}
