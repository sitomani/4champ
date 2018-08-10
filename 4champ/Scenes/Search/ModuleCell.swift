//
//  ModuleCell.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 03/08/2018.
//  Copyright © 2018 boogie. All rights reserved.
//

import UIKit

class ModuleCell: UITableViewCell {
  
  @IBOutlet weak var nameLabel: UILabel?
  @IBOutlet weak var composerLabel: UILabel?
  @IBOutlet weak var sizeLabel: UILabel?
  @IBOutlet weak var typeLabel: UILabel?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
}
