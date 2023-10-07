//
//  Playlist+CoreDataClass.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 13/04/2019.
//
//

import Foundation
import CoreData

@objc(Playlist)
public class Playlist: NSManagedObject {
    func getDisplayName() -> String {
        if self.plId == "default" {
            return "PlaylistView_DefaultPlaylist".l13n()
        }
        return self.plName ?? "<no name>"
    }
}
