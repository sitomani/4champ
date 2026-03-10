//
//  SearchModels.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol NameComparable {
  var name: String { get }
}

protocol IdComparable {
  var id: Int? { get }
}

let nameSorterBlockAsc: (NameComparable, NameComparable) -> Bool = { (compA, compB) in
  return compA.name.compare(compB.name, options: .caseInsensitive) == .orderedAscending
}

let nameSorterBlockDesc: (NameComparable, NameComparable) -> Bool = { (compA, compB) in
  return compA.name.compare(compB.name, options: .caseInsensitive) == .orderedDescending
}

let idSorterBlockAsc: (IdComparable, IdComparable) -> Bool = { (compA, compB) in
  return compA.id ?? 0 < compB.id ?? 0
}

let idSorterBlockDesc: (IdComparable, IdComparable) -> Bool = { (compA, compB) in
  return compA.id ?? 0 > compB.id ?? 0
}

struct ComposerInfo: NameComparable {
  var id: Int
  var name: String
  var realName: String
  var groups: String
}

struct GroupInfo: NameComparable {
  var id: Int
  var name: String
}

enum Search {
  struct Request {
    var text: String
    var type: SearchType
    var pagingIndex: Int = 0
  }

  struct RadioSetup {
    struct Request {
      var selection: Radio.CustomSelection?
      var appending: Bool = false
    }
    struct Response {
      var channelName: String?
      var moduleCount: Int
      var appending: Bool = false
    }
    struct ViewModel {
      var message: String
    }
  }

  struct ProgressResponse {
    var progress: Float
    var error: Error?
    struct ViewModel {
      var progress: Float
      var error: String?
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
    var sortType: SortType?
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
struct ModuleResult: Decodable, IdComparable, NameComparable {
  let nameBlock: LabelHref
  let composer: LabelHref
  let format: String
  let size, downloadCount: String
  let infos: String
  let note: String
  
  var id: Int? {
    let modUri = URL.init(string: nameBlock.href)
    var id: Int = 0
    if let idString = modUri?.query?.split(separator: "=").last {
        id = Int(idString) ?? 0
    }
    return id
  }
  var name: String {
    return nameBlock.label
  }
  
  enum CodingKeys: String, CodingKey {
    case nameBlock = "name"
    case composer, format, size, downloadCount, infos, note
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
  func sortedResult(sortType: SortType?) -> [ModuleResult] {
    return sortModules(modules: result, sortType: sortType)
  }
}

func sortModules<T: IdComparable & NameComparable>(modules: [T], sortType: SortType?) -> [T] {
  var sortedModules: [T] = []
  switch sortType {
  case .idDescending:
    sortedModules = modules.sorted(by: idSorterBlockDesc)
  case .idAscending:
    sortedModules = modules.sorted(by: idSorterBlockAsc)
  case .nameDescending:
    sortedModules = modules.sorted(by: nameSorterBlockDesc)
  case .nameAscending, .none:
    sortedModules = modules.sorted(by: nameSorterBlockAsc)
  }
  return sortedModules
}
