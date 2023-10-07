//
//  Playlist+CoreDataProperties.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 13/04/2019.
//
//

import Foundation
import CoreData

extension Playlist: Identifiable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist")
    }

    @NSManaged public var locked: NSNumber?
    @NSManaged public var playhead: NSNumber?
    @NSManaged public var playmode: NSNumber?
    @NSManaged public var plId: String?
    @NSManaged public var plName: String?
    @NSManaged public var position: NSNumber?
    @NSManaged public var modules: NSOrderedSet?

    public var id: String {
        return plId ?? UUID().uuidString
    }
}

// MARK: Generated accessors for modules
extension Playlist {

    @objc(insertObject:inModulesAtIndex:)
    @NSManaged public func insertIntoModules(_ value: ModuleInfo, at idx: Int)

    @objc(removeObjectFromModulesAtIndex:)
    @NSManaged public func removeFromModules(at idx: Int)

    @objc(insertModules:atIndexes:)
    @NSManaged public func insertIntoModules(_ values: [ModuleInfo], at indexes: NSIndexSet)

    @objc(removeModulesAtIndexes:)
    @NSManaged public func removeFromModules(at indexes: NSIndexSet)

    @objc(replaceObjectInModulesAtIndex:withObject:)
    @NSManaged public func replaceModules(at idx: Int, with value: ModuleInfo)

    @objc(replaceModulesAtIndexes:withModules:)
    @NSManaged public func replaceModules(at indexes: NSIndexSet, with values: [ModuleInfo])

    @objc(addModulesObject:)
    @NSManaged public func addToModules(_ value: ModuleInfo)

    @objc(removeModulesObject:)
    @NSManaged public func removeFromModules(_ value: ModuleInfo)

    @objc(addModules:)
    @NSManaged public func addToModules(_ values: NSOrderedSet)

    @objc(removeModules:)
    @NSManaged public func removeFromModules(_ values: NSOrderedSet)

}
