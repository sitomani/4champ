//
//  LocalModels.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

enum LocalSortKey: Int {
  case module
  case size
  case type
  case favorite
  case composer
  case playCount
  case lastPlayed
  case added
}

enum SpecialFunctions: Int {
  case filter = -1
  case `import` = -2
}

enum Local {
  // MARK: Use cases
  enum SortFilter {
    struct Request {
      let sortKey: LocalSortKey
      let filterText: String?
      let ascending: Bool
    }
    struct Response {
    }
    struct ViewModel {
    }
  }
  enum Import {
    struct Request {
      let urls: [URL]
    }
    struct Response {
      let modules: [MMD]
      let importResults: [ImportResultType]
    }
    struct ViewModel {
      let summary: String
      let modulenames: String
      let moduleIds: [Int]
    }
  }
  
  enum Delete {
    struct Request {
      let moduleIds: [Int]
    }
  }
  
  enum Assign {
    struct Request {
      let moduleIds: [Int]
      let composerName: String
    }
  }
}
