//
//  RadioSessionCell.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 20.10.2021.
//  Copyright © 2021 boogie. All rights reserved.
//

import Foundation
import UIKit

class RadioSessionCell: UITableViewCell {
    static let ReuseId = "RadioSessionCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.textColor = Appearance.veryLightGray.withAlphaComponent(0.5)
    }

    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
