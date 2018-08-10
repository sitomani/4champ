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
  enum ModuleQuery {
    struct Request {
      var text: String
    }
    struct Response {
      var result: [MMD]
    }
    struct ViewModel {
      var modules: [MMD]
    }
  }
  
  enum ComposerQuery {
    struct Request {
      var text: String
    }
    struct Response {
      var result: [ComposerInfo]
    }
  }
  
  enum GroupQuery {
    struct Request {
      var text: String
    }
    struct Response {
      var result: [String]
    }
  }
  
  enum MetaQuery {
    struct Request {
      var text: String
    }
  }
  
}
