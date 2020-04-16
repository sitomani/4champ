//
//  ModuleSharing.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 13.4.2020.
//  Copyright © 2020 boogie. All rights reserved.
//

import Foundation
import UIKit

class ShareUtility: NSObject, UIActivityItemSource {
  private var sharedMod: MMD?

  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
    return ""
  }
  
  func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    guard let modName = sharedMod?.name, let composer = sharedMod?.composer, let _ = sharedMod?.id else {
      return nil
    }
    let shareString = String.init(format: "Share_DefaultMessage".l13n(), modName, composer)
    return shareString
  }
  
  func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
    guard let modName = sharedMod?.name, let composer = sharedMod?.composer, let _ = sharedMod?.id else {
      return ""
    }
    let shareString = String.init(format: "Share_DefaultMessage".l13n(), modName, composer)
    return shareString
  }

  func shareMod(mod: MMD?, presentingVC: UIViewController? = nil) {
    guard let hostVC = presentingVC ?? ShareUtility.topMostController() else {
      log.error("Can't share without a host view")
      return
    }
    
    var sourceView: UIView? = nil
    if let mainVC = UIApplication.shared.windows[0].rootViewController as? MainViewController {
      sourceView = mainVC.tabBar
    }

    self.sharedMod = mod
    let shareUrl = URL.init(string: "https://4champ.net/mod?id=\(mod!.id!)")!

    let activityVC = UIActivityViewController.init(activityItems: [self, shareUrl], applicationActivities: nil)
    activityVC.excludedActivityTypes = [.addToReadingList, .assignToContact, .markupAsPDF, .openInIBooks, .print, .saveToCameraRoll]

    if UIDevice.current.userInterfaceIdiom == .pad {
      activityVC.modalPresentationStyle = .popover
      if let presentationController = activityVC.presentationController as? UIPopoverPresentationController {
        presentationController.sourceView = sourceView ?? hostVC.view
        presentationController.sourceRect = CGRect.init(x: 0, y: 0, width: hostVC.view.frame.width, height: sourceView!.frame.height)
        presentationController.permittedArrowDirections = [.down]
        presentationController.backgroundColor = UIColor.white
      }
      hostVC.present(activityVC, animated: true)
    } else {
      hostVC.present(activityVC, animated: true)
    }
  }
  
  static func topMostController() -> UIViewController? {
     let window = UIApplication.shared.windows[0]
     guard let rootViewController = window.rootViewController else {
          return nil
      }

      var topController = rootViewController

      while let newTopController = topController.presentedViewController {
          topController = newTopController
      }

      return topController
  }
}
