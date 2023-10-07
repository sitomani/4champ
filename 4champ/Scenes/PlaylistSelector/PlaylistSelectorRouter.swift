//
//  PlaylistSelectorRouter.swift
//  4champ
//
//  Created by Aleksi Sitomaniemi on 13.3.2020.
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

@objc protocol PlaylistSelectorRoutingLogic {
  // func routeToSomewhere(segue: UIStoryboardSegue?)
}

protocol PlaylistSelectorDataPassing {
  var dataStore: PlaylistSelectorDataStore? { get }
}

class PlaylistSelectorRouter: NSObject, PlaylistSelectorRoutingLogic, PlaylistSelectorDataPassing {
  var dataStore: PlaylistSelectorDataStore?
  
  // MARK: Routing
  
  // func routeToSomewhere(segue: UIStoryboardSegue?)
  // {
  //  if let segue = segue {
  //    let destinationVC = segue.destination as! SomewhereViewController
  //    var destinationDS = destinationVC.router!.dataStore!
  //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
  //  } else {
  //    let storyboard = UIStoryboard(name: "Main", bundle: nil)
  //    let destinationVC = storyboard.instantiateViewController(withIdentifier: "SomewhereViewController") as! SomewhereViewController
  //    var destinationDS = destinationVC.router!.dataStore!
  //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
  //    navigateToSomewhere(source: viewController!, destination: destinationVC)
  //  }
  // }

  // MARK: Navigation
  
  // func navigateToSomewhere(source: PlaylistSelectorViewController, destination: SomewhereViewController)
  // {
  //  source.show(destination, sender: nil)
  // }
  
  // MARK: Passing data
  
  // func passDataToSomewhere(source: PlaylistSelectorDataStore, destination: inout SomewhereDataStore)
  // {
  //  destination.name = source.name
  // }
}
