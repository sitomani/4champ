//
//  SearchModels.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

struct ComposerInfo {
  var name: String
  var realName: String
  var groups: String
}

enum Search
{
  struct Request {
    var text: String
    var type: SearchType
  }
  
  struct ModuleResponse {
    var result: [SearchResultModule]
  }
  
  struct ComposerResponse {
    var result: [ComposerInfo]
  }

  struct GroupResponse {
    var result: [String]
  }
  
  struct ViewModel {
    var modules: [MMD]
    var composers: [ComposerInfo]
    var groups: [String]
  }
}
