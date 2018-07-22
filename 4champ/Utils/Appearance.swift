//
//  Appearance.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 25/06/2018.
//  Copyright © 2018 boogie. All rights reserved.
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
