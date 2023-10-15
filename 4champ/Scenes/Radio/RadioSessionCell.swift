//
//  RadioSessionCell.swift
//  ampplayer
//
//  Copyright © 2021 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import UIKit

class RadioSessionCell: UITableViewCell {
    static let ReuseId = "RadioSessionCell"

    let moduleTitle: UILabel = UILabel.init(frame: .zero)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.removeFromSuperview()

        moduleTitle.translatesAutoresizingMaskIntoConstraints = false

        moduleTitle.textColor = Appearance.veryLightGray.withAlphaComponent(0.8)
        let descriptor = UIFontDescriptor.init(fontAttributes: [.family: "DIN Alternate"])
        let fnt = UIFont.init(descriptor: descriptor, size: 13.0)
        moduleTitle.font = fnt

        let separatorView = UIView.init(frame: .zero)
        separatorView.backgroundColor = Appearance.radioSeparatorColor
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        contentView.addSubview(moduleTitle)
        NSLayoutConstraint.activate([
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            separatorView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -40),
            separatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        NSLayoutConstraint.activate([
            moduleTitle.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -40),
            moduleTitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            moduleTitle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
