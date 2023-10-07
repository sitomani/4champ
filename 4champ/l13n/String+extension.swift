//
//  String+extension.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//
import Foundation

extension String {
  func l13n() -> String {
    var loc = NSLocalizedString(self, comment: "")
    if loc.compare(self) == ComparisonResult.orderedSame {
      loc = fallbackL13N(debugPrefix: "_") // loc key found but no translation
    } else if loc.count == 0 {
      loc = fallbackL13N(debugPrefix: "#") // no loc key found in strings
    }
    return finalL13N(locString: loc)
  }
  
  private func fallbackL13N(debugPrefix: String) -> String {
    let fallbackLoc: String
    if let bundlePath = Bundle.main.path(forResource: "en", ofType: "lproj"),
      let bundle = Bundle.init(path: bundlePath) {
      fallbackLoc = bundle.localizedString(forKey: self, value: "", table: nil)
    } else {
      fallbackLoc = self
    }
    
    #if DEBUG
    return debugPrefix + fallbackLoc
    #else
    return fallbackLoc
    #endif
  }
  
  private func finalL13N(locString: String) -> String {
    // apply format fixes for string parameters
    var loc = locString
    loc = loc.replacingOccurrences(of: "%s", with: "%@")
    loc = loc.replacingOccurrences(of: "$s", with: "$@")
    loc = loc.replacingOccurrences(of: "$d", with: "$d")
    loc = loc.replacingOccurrences(of: "\\n", with: "\n")
    return loc
  }
}
