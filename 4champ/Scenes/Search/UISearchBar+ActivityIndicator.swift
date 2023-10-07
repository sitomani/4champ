//
//  UISearchBar+ActivityIndicator.swift
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import UIKit

/// UISearchBar extension that enables showing a spinner in place of clear button
/// when a network search is ongoing
extension UISearchBar {
  public var activityIndicator: UIActivityIndicatorView? {
    let hostView: UIView?
    if subviews.count > 1 {
      hostView = self
    } else {
      hostView = subviews.first
    }
    return hostView?.subviews.compactMap {
      return $0 as? UIActivityIndicatorView }.first
  }

  public var queryField: UITextField? {
    if #available(iOS 13, *) {
        return self.searchTextField
    }
    return subviews.first?.subviews.compactMap {
      $0 as? UITextField
      }.first
  }

  /// Property that controls whether the search spinner is shown or not
  var searching: Bool {
    get {
      return activityIndicator != nil
    }
    set {
      if newValue {
        guard activityIndicator == nil else {
          return
        }
        queryField?.clearButtonMode = .never
        let indicator = UIActivityIndicatorView.init(style: .medium)
        self.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.rightAnchor.constraint(equalTo: queryField!.rightAnchor, constant: -5).isActive = true
        indicator.centerYAnchor.constraint(equalTo: queryField!.centerYAnchor).isActive = true
        indicator.startAnimating()
      } else {
        queryField?.clearButtonMode = .always
        if let indicator = self.activityIndicator {
          indicator.stopAnimating()
          indicator.removeFromSuperview()
        }
      }
    }
  }
}
