//
//  LocalRouter.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//


import UIKit

@objc protocol LocalRoutingLogic
{
  //func routeToSomewhere(segue: UIStoryboardSegue?)
}

protocol LocalDataPassing
{
  var dataStore: LocalDataStore? { get }
}

class LocalRouter: NSObject, LocalRoutingLogic, LocalDataPassing
{
  weak var viewController: LocalViewController?
  var dataStore: LocalDataStore?
  
  // MARK: Routing
  
  //func routeToSomewhere(segue: UIStoryboardSegue?)
  //{
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
  //}

  // MARK: Navigation
  
  //func navigateToSomewhere(source: LocalViewController, destination: SomewhereViewController)
  //{
  //  source.show(destination, sender: nil)
  //}
  
  // MARK: Passing data
  
  //func passDataToSomewhere(source: LocalDataStore, destination: inout SomewhereDataStore)
  //{
  //  destination.name = source.name
  //}
}
