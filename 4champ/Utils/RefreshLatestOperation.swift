//
//  BackgroundFetchOp.swift
//  ampplayer
//
//  Created by Aleksi Sitomaniemi on 15.10.2023.
//  Copyright © 2023 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import NotificationCenter
import Alamofire

class RefershLatestOperation: Operation, @unchecked Sendable {
   private var _executing = false
   private var _finished = false

   override private(set) var isExecuting: Bool {
       get {
           return _executing
       }
       set {
           willChangeValue(forKey: "isExecuting")
           _executing = newValue
           didChangeValue(forKey: "isExecuting")
       }
   }

   override private(set) var isFinished: Bool {
       get {
           return _finished
       }
       set {
           willChangeValue(forKey: "isFinished")
           _finished = newValue
           didChangeValue(forKey: "isFinished")
       }
   }

   override func start() {
       if isCancelled {
           isFinished = true
           return
       }

       isExecuting = true
       main() // Call your main method to perform the task
   }

   override func main() {
       // Send a REST request to refresh app contents
       log.debug("")
       let req = RESTRoutes.latestId
       AF.request(req).validate().responseString { resp in
           switch resp.result {
           case .failure:
               self.cancel()
           case .success(let str):
               guard let collectionSize = Int(str) else {
                   self.completeOperation()
                   return
               }
               log.info("Collection Size: \(collectionSize)")
               self.updateCollectionSize(size: collectionSize)
               self.completeOperation()
           }
       }
   }

   private func completeOperation() {
       isExecuting = false
       isFinished = true
   }

  func updateCollectionSize(size: Int) {
    log.debug("")
    settings.collectionSize = size
    let prevSize = settings.prevCollectionSize

    // Only fire the request once per a given collectionSize/diff
    if prevSize < size && settings.badgeCount < Constants.maxBadgeValue {
      let fmt = "Radio_Notification".l13n()
      let content = UNMutableNotificationContent()
      content.body = String.init(format: fmt, "\(settings.badgeCount)")
      content.categoryIdentifier = "newmodules"
      let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
      let req = UNNotificationRequest.init(identifier: "newmodules-usernotif", content: content, trigger: trigger)
      UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
      settings.prevCollectionSize = settings.collectionSize
    }
  }
}
