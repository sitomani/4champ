import Foundation
import UIKit

class UIUtils {
  class func roundCornersInView(_ view: UIView?) {
    UIUtils.roundCornersInView(view, border: true, radius: 10.0)
  }

  class func roundCornersInView(_ view: UIView?, border: Bool, radius: CGFloat) {
    guard let view = view else { return }
    if border {
      view.layer.borderWidth = 1.0
      view.layer.borderColor = UIColor.white.cgColor
    }

    view.layer.cornerRadius = radius
    view.clipsToBounds = true
  }
}
