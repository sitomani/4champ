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
  struct Request: Decodable, Encodable {
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

struct LatestModule: Codable {
  let provider: String
  let id: String
  enum CodingKeys: String, CodingKey {
    case provider
    case id
  }
}

// MARK: - ModuleDetails
struct ModuleDetailsResponse: Decodable {
  let provider: String
  let item: ModuleDetails
  
  enum CodingKeys: String, CodingKey {
    case provider
    case item
  }
}

struct ModuleSearchResponse: Decodable {
  let provider: String
  let range: Range
  let items: [ModuleDetails]
}

struct ListModulesResponse: Decodable {
  let provider: String
  let items: [ModuleDetails]
}

struct ListComposersResponse: Decodable {
  let provider: String
  let items: [ComposerDetails]
}

struct Range: Codable {
  let start: Int
  let end: Int
  
  enum CodingKeys: String, CodingKey {
    case start
    case end
  }
}

struct ComposerSearchResponse: Decodable {
  let provider: String
  let range: Range
  let items: [ComposerDetails]
}
struct GroupSearchResponse: Decodable {
  let provider: String
  let range: Range
  let items: [GroupDetails]
}

// MARK: - ModuleDetails
@propertyWrapper
struct IntFromString: Decodable {
  var wrappedValue: Int?
  
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    
    guard let value = Int(string) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Expected a string containing an integer"
      )
    }
    
    wrappedValue = value
  }
}

struct ModuleDetails: Decodable, IdComparable, NameComparable {
  let kind: String
  @IntFromString var id: Int?
  let name: String
  let composer: ModuleComposer
  let authors: [ModuleComposer]?
  let format: String
  let sizeLabel: String
  let sizeBytes: Int
  let tracker: String?
  let duration: String?
  let downloadsLabel: String
  let links: Links
  
  enum CodingKeys: String, CodingKey {
    case kind
    case id
    case name = "title"
    case composer
    case authors
    case format
    case sizeLabel
    case sizeBytes
    case tracker
    case duration
    case downloadsLabel
    case links
  }
}

struct ComposerDetails: Decodable {
  let kind: String?
  @IntFromString var id: Int?
  let handle: String
  let realName: String
  let groups: String
  let country: [DetailRef]?
  let groupRefs: [DetailRef]?
  let moduleCount: Int?
  let links: Links?
  
  enum CodingKeys: String, CodingKey {
    case kind
    case id
    case handle
    case realName
    case groups
    case country
    case groupRefs
    case moduleCount
    case links
  }
}

struct GroupDetails: Decodable {
  let kind: String
  @IntFromString var id: Int?
  let name: String
  
  enum CodingKeys: String, CodingKey {
    case kind
    case id
    case name
  }
}

// MARK: - Country
struct DetailRef: Codable {
  let id: String
  let name: String
  
  enum CodingKeys: String, CodingKey {
    case id
    case name
  }
}

// MARK: - Composer
struct ModuleComposer: Codable {
  let id: String
  let name: String
  
  enum CodingKeys: String, CodingKey {
    case id
    case name
  }
}

// MARK: - Links
struct Links: Codable {
  let source: String
  
  enum CodingKeys: String, CodingKey {
    case source
  }
}

struct ModulePathResponse: Codable {
  let provider: String
  let id: String
  let url: String
  enum CodingKeys: String, CodingKey {
    case provider
    case id
    case url
  }
}

struct GroupResult: Codable {
  let label: String
  let href: String
}

extension Search.Response where T == ModuleDetails {
  func sortedResult(sortType: SortType?) -> [ModuleDetails] {
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
