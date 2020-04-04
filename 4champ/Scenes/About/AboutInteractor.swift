//
//  AboutInteractor.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol AboutBusinessLogic
{
  var details: About.Details { get }
}

protocol AboutDataStore
{
  var details: About.Details { get }
}

class AboutInteractor: AboutBusinessLogic, AboutDataStore
{
  var presenter: AboutPresentationLogic?
  
  var details: About.Details
  
  init() {
    log.debug("")
    let aboutTitle: String
    if let ver = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
      let build = Bundle.main.object(forInfoDictionaryKey: "CWBuildNumber") as? String {
      aboutTitle = "4champ \(ver) (\(build))"
    } else {
      aboutTitle = "0.0"
    }
    let titleKeys = [aboutTitle, "Twitter","About_Copyrights", "TabBar_Local", "TabBar_Playlist", "TabBar_Search", "TabBar_Radio", "About_Licenses"]
    let contentKeys = ["AboutView_Info", "AboutView_Twitter", "AboutView_Legal", "AboutView_Local","AboutView_Playlists", "AboutView_Search", "AboutView_Radio"]
    let imageKeys = ["about", "twitter_small", "legal", "localMods", "search", /*"playlist", */ "radio", "about"]
    let lics = ["Alamofire", "GzipSwift", "HivelyTracker", "LibOpenMPT"]
    let licUrls = ["https://github.com/Alamofire/Alamofire/blob/master/LICENSE",
                   "https://github.com/1024jp/GzipSwift/blob/develop/LICENSE",
                   "HivelyTracker replayer source code is public domain, see http://www.hivelytracker.co.uk/forum.php?action=viewthread&id=114",
                   "https://lib.openmpt.org/libopenmpt/#sec_license"]
    
    details = About.Details(titles: titleKeys, contents: contentKeys, images: imageKeys, licenseLinks: licUrls, licenseNames: lics)
  }
}
