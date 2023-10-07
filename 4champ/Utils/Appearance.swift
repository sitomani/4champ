//
//  Appearance.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import UIKit

class SettingsCell: UITableViewCell {
}

class Appearance {
  static var errorColor = UIColor.init(rgb: 0xFF3B30)
  static var successColor = UIColor.init(rgb: 0x4CD964)
  static var darkBlueColor = UIColor.init(rgb: 0x0C263D)
  static var tabColor = UIColor.init(rgb: 0x0C263D)
  static var ampBgColor = UIColor.init(rgb: 0x123456)
  static var segmentBg = UIColor.init(rgb: 0x1A2F4B)
//  static var ampLightBlueColor = UIColor.init(rgb: 0x36679A)
  static var ampLightBlueColor = UIColor.init(rgb: 0x16538a)
  static var ampTextfieldBgColor = UIColor.init(rgb: 0x1f3044)
  static var separatorColor = UIColor.init(rgb: 0x485675)
  static var barTitleColor = UIColor.init(rgb: 0xc0c0c0)
  static var veryLightGray = UIColor.init(rgb: 0xf0f0f0)
  static var cellColor = UIColor.clear
  static var radioSeparatorColor = UIColor.init(rgb: 0x294976)
  
  class func setup() {
    let navigationBarAppearace = UINavigationBar.appearance()
    navigationBarAppearace.tintColor = UIColor.white
//    navigationBarAppearace.isTranslucent = false
    navigationBarAppearace.barTintColor = Appearance.tabColor
    navigationBarAppearace.backgroundColor = darkBlueColor
    navigationBarAppearace.titleTextAttributes = [.foregroundColor: barTitleColor,
                                                  .font: UIFont.systemFont(ofSize: 16.0, weight: .heavy)]
    
    let tabBarAppearance = UITabBar.appearance()
    tabBarAppearance.barTintColor = Appearance.tabColor
    
    let switchAppearance = UISwitch.appearance()
    switchAppearance.onTintColor = successColor
    
    let barButtonFont = UIFont.systemFont(ofSize: 12.0, weight: .heavy)
    UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barButtonFont], for: .normal)
    UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barButtonFont], for: .highlighted)

    let indicatorAppearance = NowPlayingView.appearance()
    indicatorAppearance.backgroundColor = Appearance.tabColor
    
    let tableCellAppearance = UITableViewCell.appearance()
    tableCellAppearance.backgroundColor = cellColor
    tableCellAppearance.selectionStyle = .none
    
    let tableViewAppearance = UITableView.appearance()
    tableViewAppearance.backgroundColor = ampBgColor
    tableViewAppearance.separatorColor = separatorColor
    
    let settingsCellAppearance = SettingsCell.appearance()
    settingsCellAppearance.backgroundColor = ampLightBlueColor
    
    let sclabelAppearance = UILabel.appearance(whenContainedInInstancesOf: [SettingsCell.self])
    sclabelAppearance.textColor = UIColor.white
    
    let sbAppearance = UISearchBar.appearance()
    sbAppearance.barTintColor = darkBlueColor
    
    let sgAppearance = UISegmentedControl.appearance()
    sgAppearance.tintColor = .white
    sgAppearance.selectedSegmentTintColor = .white
    
    }
}
