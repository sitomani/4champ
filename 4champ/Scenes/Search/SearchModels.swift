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
    var error: Error? = nil
    struct ViewModel {
      var progress: Float
      var error: String? = nil
    }
  }
  
  struct BatchDownload {
    struct Request {
      var moduleIds: [Int]
      var favorite: Bool = false
    }
    struct Response {
      var originalQueueLength: Int
      var queueLength: Int
      var complete: Bool
      var favoritedModuleId: Int
    }
    struct ViewModel {
      var batchSize: Int
      var processed: Int
      var complete: Bool
      var favoritedModuleId: Int
    }
  }
  
  struct Response<T> {
    var result: [T]
    var text: String
  }
  
  struct ViewModel {
    var modules: [MMD]
    var composers: [ComposerInfo]
    var groups: [GroupInfo]
    var text: String
  }
  
  enum MetaDataChange {
    struct Response {
      var module: MMD
    }
    
    struct ViewModel {
      var module: MMD
    }
  }
}

// MARK: 4champ.net JSON interface objects
struct ModuleResult: Codable {
  let name, composer: LabelHref
  let format: String
  let size, downloadCount: String
  let infos: String
  let note: String
  func getId() -> Int {
    let modUri = URL.init(string: name.href)
    var id: Int = 0
    if let idString = modUri?.query?.split(separator: "=").last {
        id = Int(idString) ?? 0
    }
    return id
  }
}

struct LabelHref: Codable {
  let label: String
  let href: String
}


struct ComposerResult: Codable {
  let handle: LabelHref
  let realname, groups: String
}

struct GroupResult: Codable {
  let label: String
  let href: String
}

extension Search.Response where T == ModuleResult {
  func sortedResult() -> [ModuleResult] {
    let r = result.sorted { (a, b) -> Bool in
      return a.name.label.compare(b.name.label, options: .caseInsensitive) == .orderedAscending
    }
    return r
  }
}
