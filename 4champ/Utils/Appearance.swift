//
//  Appearance.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import UIKit

class Appearance {
  class func setup() {
    let navigationBarAppearace = UINavigationBar.appearance()
    navigationBarAppearace.tintColor = UIColor.init(rgb: 0xffffff)
    navigationBarAppearace.barTintColor = UIColor.init(rgb: 0x0B1F33)
    navigationBarAppearace.titleTextAttributes = [.foregroundColor: UIColor.init(rgb: 0xc6c6c6),
                                                  .font: UIFont.systemFont(ofSize: 16.0, weight: .heavy)]
    
    let tabBarAppearance = UITabBar.appearance()
    tabBarAppearance.barTintColor = UIColor.init(rgb: 0x0B1F33)
  }
}
