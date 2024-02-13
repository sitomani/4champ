//
//  ReviewActions.swift
//  ampplayer
//
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import StoreKit

extension SKStoreReviewController {
    public static func requestReviewInCurrentScene() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            DispatchQueue.main.async {
                requestReview(in: scene)
            }
        }
    }
}

/// Enumeration used to trigger AppStore review requests
enum ReviewActions: String {

    /// number of calls to `ReviewActions.increment`needed to raise the review request
    static let reviewTriggerThreshold = 5

    case noteworthyActionCount
    case lastReviewRequestVersion

    /// Resets the review trigger values (used in Debug mode only)
    static func reset() {
        let defaults = UserDefaults.standard
        defaults.set(0, forKey: ReviewActions.noteworthyActionCount.rawValue)
        defaults.set(nil, forKey: ReviewActions.lastReviewRequestVersion.rawValue)
    }

    /// Increment the review actions count. When the specified threshold is reached, requests review using StoreKit API.
    static func increment() {
        let bundle = Bundle.main
        let defaults = UserDefaults.standard

        var actionCount = defaults.integer(forKey: ReviewActions.noteworthyActionCount.rawValue)
        actionCount += 1
        defaults.set(actionCount, forKey: ReviewActions.noteworthyActionCount.rawValue)

        guard actionCount >= ReviewActions.reviewTriggerThreshold else {
            return
        }

        let bundleVersionKey = kCFBundleVersionKey as String
        let currentVersion = bundle.object(forInfoDictionaryKey: bundleVersionKey) as? String
        let lastVersion = defaults.string(forKey: ReviewActions.lastReviewRequestVersion.rawValue)

        // Don't request review for same version twice
        guard lastVersion == nil || lastVersion != currentVersion else {
            return
        }

        SKStoreReviewController.requestReviewInCurrentScene()

        // Reset the defaults
        defaults.set(0, forKey: ReviewActions.noteworthyActionCount.rawValue)
        defaults.set(currentVersion, forKey: ReviewActions.lastReviewRequestVersion.rawValue)
    }

    /// Manually open app review in AppStore (from About page)
    static func giveReview() {
        guard let prodUrl = URL.init(string: "https://apps.apple.com/app/id578311010") else {
            return
        }

        var components = URLComponents(url: prodUrl, resolvingAgainstBaseURL: false)

        components?.queryItems = [
          URLQueryItem(name: "action", value: "write-review")
        ]

        guard let writeReviewURL = components?.url else {
          return
        }
        UIApplication.shared.open(writeReviewURL)
    }
}
