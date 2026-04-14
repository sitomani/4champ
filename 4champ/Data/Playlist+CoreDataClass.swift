//
//  Playlist+CoreDataClass.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 13/04/2019.
//
//

import Foundation
import CoreData

protocol PLCDOPresentable: class {
  func getDisplayName() -> String
  func getModuleCount() -> Int
  func getPlId() -> String
}

@objc(Playlist)
public class Playlist: NSManagedObject, PLCDOPresentable {
  func getModuleCount() -> Int {
    return self.modules?.count ?? 0
  }
  
  func getPlId() -> String {
    return self.plId ?? "default"
  }
  
    func getDisplayName() -> String {
        if self.plId == "default" {
            return "PlaylistView_DefaultPlaylist".l13n()
        }
        return self.plName ?? "<no name>"
    }
}
