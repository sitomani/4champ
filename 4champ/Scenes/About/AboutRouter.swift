//
//  AboutRouter.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

@objc protocol AboutRoutingLogic {
  // func routeToSomewhere(segue: UIStoryboardSegue?)
}

protocol AboutDataPassing {
  var dataStore: AboutDataStore? { get }
}

class AboutRouter: NSObject, AboutRoutingLogic, AboutDataPassing {
  weak var viewController: AboutViewController?
  var dataStore: AboutDataStore?
}
