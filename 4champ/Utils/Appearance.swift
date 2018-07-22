//
//  Appearance.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import UIKit

class Appearance {
  static var errorColor = UIColor.init(rgb: 0xFF3B30)
  static var successColor = UIColor.init(rgb: 0x4CD964)
  static var darkBlueColor = UIColor.init(rgb: 0x0C263D)
  static var tabColor = UIColor.init(rgb: 0x0C263D)
  
  class func setup() {
    let navigationBarAppearace = UINavigationBar.appearance()
    navigationBarAppearace.tintColor = UIColor.white
    navigationBarAppearace.barTintColor = Appearance.tabColor
    navigationBarAppearace.titleTextAttributes = [.foregroundColor: UIColor.init(rgb: 0xc6c6c6),
                                                  .font: UIFont.systemFont(ofSize: 16.0, weight: .heavy)]
    
    let tabBarAppearance = UITabBar.appearance()
    tabBarAppearance.barTintColor = Appearance.tabColor
    
    let switchAppearance = UISwitch.appearance()
    switchAppearance.onTintColor = successColor
    
    let indicatorAppearance = NowPlayingView.appearance()
    indicatorAppearance.backgroundColor = Appearance.tabColor
  }
}
