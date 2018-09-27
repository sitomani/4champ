//
//  SearchModels.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

struct ComposerInfo {
  var id: Int
  var name: String
  var realName: String
  var groups: String
}

struct GroupInfo {
  var id: Int
  var name: String
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
    var result: [SearchResultComposer]
  }

  struct GroupResponse {
    var result: [LabelHref]
  }
  
  struct ViewModel {
    var modules: [MMD]
    var composers: [ComposerInfo]
    var groups: [GroupInfo]
  }
}
