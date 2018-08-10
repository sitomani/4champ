//
//  SearchInteractor.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniem. All rights reserved.
//

import UIKit

protocol SearchBusinessLogic
{
  func doSomething(request: Search.ModuleQuery.Request)
}

protocol SearchDataStore
{
  //var name: String { get set }
}

class SearchInteractor: SearchBusinessLogic, SearchDataStore
{
  var presenter: SearchPresentationLogic?
  var worker: SearchWorker?
  //var name: String = ""
  
  // MARK: Do something
  
  func doSomething(request: Search.ModuleQuery.Request)
  {
//    let request = RESTRoutes.search(type: <#T##SearchType#>, text: <#T##String#>, position: <#T##Int#>)
//    worker = SearchWorker()
//    worker?.doSomeWork()
//
//    let response = Search.Something.Response()
//    presenter?.presentSomething(response: response)
  }
}
