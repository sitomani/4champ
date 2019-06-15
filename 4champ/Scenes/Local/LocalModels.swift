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

enum Local
{
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
}
