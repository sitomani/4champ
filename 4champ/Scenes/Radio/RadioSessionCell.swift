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
        textLabel?.textColor = Appearance.veryLightGray.withAlphaComponent(0.8)
        let descriptor = UIFontDescriptor.init(fontAttributes: [.family : "DIN Alternate"])
        let fnt = UIFont.init(descriptor: descriptor, size: 13.0)
        textLabel?.font = fnt
        
        let separatorView = UIView.init(frame: .zero)
        separatorView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            separatorView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -40),
            separatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
