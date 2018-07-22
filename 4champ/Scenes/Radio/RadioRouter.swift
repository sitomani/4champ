//
//  RadioRouter.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

@objc protocol RadioRoutingLogic
{
  //func routeToSomewhere(segue: UIStoryboardSegue?)
}

protocol RadioDataPassing
{
  var dataStore: RadioDataStore? { get }
}

class RadioRouter: NSObject, RadioRoutingLogic, RadioDataPassing
{
  weak var viewController: RadioViewController?
  var dataStore: RadioDataStore?
}
