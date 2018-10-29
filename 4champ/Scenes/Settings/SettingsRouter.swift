//
//  SettingsRouter.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

@objc protocol SettingsRoutingLogic
{
  //func routeToSomewhere(segue: UIStoryboardSegue?)
}

protocol SettingsDataPassing
{
  var dataStore: SettingsDataStore? { get }
}

class SettingsRouter: NSObject, SettingsRoutingLogic, SettingsDataPassing
{
  weak var viewController: SettingsViewController?
  var dataStore: SettingsDataStore?
}
