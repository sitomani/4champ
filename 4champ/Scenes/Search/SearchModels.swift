//
//  SearchModels.swift
//  4champ Amiga Music Player
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
    var pagingIndex: Int = 0
  }
  
  struct ProgressResponse {
    var progress: Float
    struct ViewModel {
      var progress: Float
    }
  }
  
  struct BatchDownload {
    struct Request {
      var moduleIds: [Int]
    }
    struct Response {
      var originalQueueLength: Int
      var queueLength: Int
      var complete: Bool
    }
    struct ViewModel {
      var batchSize: Int
      var processed: Int
      var complete: Bool
    }
  }
  
  struct ModuleResponse {
    var result: [SearchResultModule]
    var text: String
  }
  
  struct ComposerResponse {
    var result: [SearchResultComposer]
    var text: String
  }

  struct GroupResponse {
    var result: [LabelHref]
    var text: String
  }
  
  struct ViewModel {
    var modules: [MMD]
    var composers: [ComposerInfo]
    var groups: [GroupInfo]
    var text: String
  }
}

// MARK: 4champ.net JSON interface objects
typealias ModuleResult = [SearchResultModule]

struct SearchResultModule: Codable {
  let name, composer: LabelHref
  let format: String
  let size, downloadCount: String
  let infos: String
}

struct LabelHref: Codable {
  let label: String
  let href: String
}

typealias ComposerResult = [SearchResultComposer]

struct SearchResultComposer: Codable {
  let handle: LabelHref
  let realname, groups: String
}

typealias GroupResult = [LabelHref]
