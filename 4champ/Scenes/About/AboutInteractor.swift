//
//  AboutInteractor.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

struct AppInfo {

    var appName: String {
        return readFromInfoPlist(withKey: "CFBundleName") ?? "(unknown app name)"
    }

    var version: String {
        return readFromInfoPlist(withKey: "CFBundleShortVersionString") ?? "(unknown app version)"
    }

    var build: String {
        return readFromInfoPlist(withKey: "CFBundleVersion") ?? "(unknown build number)"
    }

    var minimumOSVersion: String {
        return readFromInfoPlist(withKey: "MinimumOSVersion") ?? "(unknown minimum OSVersion)"
    }

    var copyrightNotice: String {
        return readFromInfoPlist(withKey: "NSHumanReadableCopyright") ?? "(unknown copyright notice)"
    }

    var bundleIdentifier: String {
        return readFromInfoPlist(withKey: "CFBundleIdentifier") ?? "(unknown bundle identifier)"
    }

    var developer: String { return "my awesome name" }

    // lets hold a reference to the Info.plist of the app as Dictionary
    private let infoPlistDictionary = Bundle.main.infoDictionary

    /// Retrieves and returns associated values (of Type String) from info.Plist of the app.
    private func readFromInfoPlist(withKey key: String) -> String? {
        return infoPlistDictionary?[key] as? String
    }
}

protocol AboutBusinessLogic {
    var details: About.Details { get }
}

protocol AboutDataStore {
    var details: About.Details { get }
}

class AboutInteractor: AboutBusinessLogic, AboutDataStore {
    var presenter: AboutPresentationLogic?

    var details: About.Details

    init() {
        log.debug("")
        let aboutTitle = "4champ \(AppInfo().version) (\(AppInfo().build))"
        let titleKeys = [aboutTitle,
                         "Social_Check",
                         "About_Copyrights",
                         "TabBar_Local",
                         "TabBar_Playlist",
                         "TabBar_Search",
                         "TabBar_Radio",
                         "About_Licenses"]
        let contentKeys = ["AboutView_Info",
                           "AboutView_Social",
                           "AboutView_Legal",
                           "AboutView_Local",
                           "AboutView_Playlists",
                           "AboutView_Search",
                           "AboutView_Radio"]
        let imageKeys = ["about", "mastodon_small", "legal", "localMods", "playlist", "search", "radio", "about"]
        let lics = ["GzipSwift", "HivelyTracker", "LibOpenMPT", "UADE"]
        let licUrls = ["https://github.com/1024jp/GzipSwift/blob/develop/LICENSE",
                       "HivelyTracker replayer source code is public domain," +
                       "see http://www.hivelytracker.co.uk/forum.php?action=viewthread&id=114",
                       "https://lib.openmpt.org/libopenmpt/license/",
                       "https://gitlab.com/uade-music-player/uade/-/blob/master/COPYING"]

        details = About.Details(titles: titleKeys, contents: contentKeys, images: imageKeys, licenseLinks: licUrls, licenseNames: lics)
    }
}
