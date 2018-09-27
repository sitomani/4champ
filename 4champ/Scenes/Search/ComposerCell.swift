//
//  ComposerCell.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 27/09/2018.
//  Copyright © 2018 boogie. All rights reserved.
//

import UIKit

class ComposerCell: UITableViewCell {

  @IBOutlet weak var nameLabel: UILabel?
  @IBOutlet weak var realNameLabel: UILabel?
  @IBOutlet weak var groupsLabel: UILabel?
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
